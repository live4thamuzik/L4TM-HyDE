#!/usr/bin/env bash
# shellcheck disable=SC2154
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| Prasanth Rangan          |-/ /--|#
#|/ /---+--------------------------+/ /---|#

cat <<"EOF"

-------------------------------------------------
        .
       / \         _       _  _      ___  ___
      /^  \      _| |_    | || |_  _|   \| __|
     /  _  \    |_   _|   | __ | || | |) | _|
    /  | | ~\     |_|     |_||_|\_, |___/|___|
   /.-'   '-.\                  |__/

-------------------------------------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Source backup/restore functions from restore_cfg.sh (functions are defined at the top, before deploy_list)
# shellcheck disable=SC1091
source <(head -n 157 "${scrDir}/restore_cfg.sh")

#------------------#
# evaluate options #
#------------------#
flg_Install=0
flg_Restore=0
flg_Service=0
flg_DryRun=0
flg_Shell=0
flg_Nvidia=1
flg_ThemeInstall=1

while getopts idrstmnh RunStep; do
    case $RunStep in
    i) flg_Install=1 ;;
    d)
        flg_Install=1
        export use_default="--noconfirm"
        ;;
    r) flg_Restore=1 ;;
    s) flg_Service=1 ;;
    n)
        # shellcheck disable=SC2034
        export flg_Nvidia=0
        print_log -r "[nvidia] " -b "Ignored :: " "skipping Nvidia actions"
        ;;
    h)
        # shellcheck disable=SC2034
        export flg_Shell=1
        print_log -r "[shell] " -b "Reevaluate :: " "shell options"
        ;;
    t) flg_DryRun=1 ;;
    m) flg_ThemeInstall=0 ;;
    *)
        cat <<EOF
Usage: $0 [options]
            i : [i]nstall hyprland without configs
            d : install hyprland [d]efaults without configs --noconfirm
            r : [r]estore config files
            s : enable system [s]ervices
            n : ignore/[n]o [n]vidia actions (-irsn to ignore nvidia, AMD/Intel still detected)
            h : re-evaluate S[h]ell
            m : no the[m]e reinstallations
            t : [t]est run without executing (-irst to dry run all)

NOTE:
        running without args is equivalent to -irs
        to ignore nvidia, run -irsn

WRONG:
        install.sh -n # This will not work

EOF
        exit 1
        ;;
    esac
done

# Only export that are used outside this script
HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export flg_DryRun flg_Nvidia flg_Shell flg_Install flg_ThemeInstall HYDE_LOG

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
elif [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
    flg_Service=1
fi


#--------------------#
# pre-install script #
#--------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${scrDir}/install_pre.sh"
fi

#------------#
# installing #
#------------#
if [ ${flg_Install} -eq 1 ]; then
    cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #----------------------#
    # prepare package list #
    #----------------------#
    shift $((OPTIND - 1))
    custom_pkg=$1
    cp "${scrDir}/pkg_core.lst" "${scrDir}/install_pkg.lst"
    trap 'mv "${scrDir}/install_pkg.lst" "${cacheDir}/logs/${HYDE_LOG}/install_pkg.lst"' EXIT

    echo -e "\n#user packages" >>"${scrDir}/install_pkg.lst" # Add a marker for user packages
    if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
        cat "${custom_pkg}" >>"${scrDir}/install_pkg.lst"
    fi


    #----------------#
    # backup configs #
    #----------------#
    print_log -sec "CONFIG" -stat "backing up" "user configurations"
    if [[ ${flg_DryRun} -ne 1 ]]; then
        # Create backup directory
        backup_dir="${cacheDir}/cfg_backups/$(date +'%y%m%d_%Hh%Mm%Ss')"
        mkdir -p "$backup_dir"
        
        # Backup Dolphin configuration
        backup_dolphin_config "$backup_dir"
        
        # Backup Hyprland configuration
        backup_hyprland_config "$backup_dir"
        
        # Protect from HyDE overwrites
        protect_dolphin_config
        protect_hyprland_config
    else
        print_log -sec "CONFIG" -stat "would backup" "user configurations (dry run)"
    fi

    #----------------#
    # get user prefs #
    #----------------#
    # AUR integration removed in fork - no automatic AUR helper installation
    # Check if user already has an AUR helper installed (for optional packages)
    if ! chk_list "aurhlpr" "${aurList[@]}"; then
        print_log -sec "AUR" -stat "info" "No AUR helper detected (optional packages like hyde-cli-git will be skipped)"
        print_log -sec "AUR" -stat "info" "Install manually if needed: yay -S hyde-cli-git"
    else
        print_log -g "[AUR] " "AUR helper detected: ${aurhlpr} (optional packages available)"
    fi

    # Shell selection with bash, zsh, fish options
    if ! chk_list "myShell" "${shlList[@]}"; then
        print_log -c "Shell Selection :: "
        print_log -sec "1" " bash (default)"
        print_log -sec "2" " zsh"
        print_log -sec "3" " fish"
        prompt_timer 120 "Enter option number [default: 1] | s to skip "

        case "${PROMPT_INPUT}" in
        1|"")
            export myShell="bash"
            # bash is already in pkg_core.lst, no need to add
            ;;
        2)
            export myShell="zsh"
            echo "zsh" >>"${scrDir}/install_pkg.lst"
            ;;
        3)
            export myShell="fish"
            echo "fish" >>"${scrDir}/install_pkg.lst"
            ;;
        s|S|skip|SKIP)
            print_log -sec "shell" -warn "Skipped" "Using current shell, no additional shell will be installed"
            export myShell="$(basename "$SHELL")"
            ;;
        *)
            print_log -sec "shell" -warn "Defaulting to bash"
            export myShell="bash"
            ;;
        esac
        
        print_log -sec "shell" -stat "selected" "${myShell}"
    fi

    # Terminal selection: Kitty (default) or Alacritty
    if ! pkg_installed kitty && ! pkg_installed alacritty; then
        print_log -c "Terminal Selection :: "
        print_log -sec "1" " Kitty (default)"
        print_log -sec "2" " Alacritty"
        prompt_timer 120 "Enter option number [default: 1] | s to skip "

        case "${PROMPT_INPUT}" in
        1|"")
            export myTerminal="kitty"
            echo "kitty" >>"${scrDir}/install_pkg.lst"
            print_log -sec "terminal" -stat "selected" "Kitty"
            ;;
        2)
            export myTerminal="alacritty"
            echo "alacritty" >>"${scrDir}/install_pkg.lst"
            print_log -sec "terminal" -stat "selected" "Alacritty"
            ;;
        s|S|skip|SKIP)
            print_log -sec "terminal" -warn "Skipped" "No terminal will be installed"
            export myTerminal=""
            ;;
        *)
            print_log -sec "terminal" -warn "Defaulting to Kitty"
            export myTerminal="kitty"
            echo "kitty" >>"${scrDir}/install_pkg.lst"
            ;;
        esac
    elif pkg_installed kitty; then
        export myTerminal="kitty"
        print_log -g "[TERMINAL] " "Kitty already installed"
    elif pkg_installed alacritty; then
        export myTerminal="alacritty"
        print_log -g "[TERMINAL] " "Alacritty already installed"
    fi

    # Prompt tool selection: oh-my-posh or starship
    if ! pkg_installed oh-my-posh && ! pkg_installed starship && ! pkg_installed starship-git; then
        print_log -c "Prompt Tool Selection :: "
        print_log -sec "1" " oh-my-posh (default, AUR package)"
        print_log -sec "2" " starship (AUR package)"
        print_log -sec "3" " None (skip prompt theming)"
        prompt_timer 120 "Enter option number [default: 1] | s to skip "

        case "${PROMPT_INPUT}" in
        1|"")
            export myPrompt="oh-my-posh"
            # oh-my-posh is AUR, will be handled separately
            if chk_list "aurhlpr" "${aurList[@]}"; then
                echo "oh-my-posh" >>"${scrDir}/install_pkg.lst"
                print_log -sec "prompt" -stat "selected" "oh-my-posh (will install via AUR)"
            else
                print_log -sec "prompt" -warn "No AUR helper" "Skipping oh-my-posh installation"
                print_log -sec "prompt" -stat "info" "Install manually later: yay -S oh-my-posh"
            fi
            ;;
        2)
            export myPrompt="starship"
            # starship requires the selected shell
            if [[ "${myShell}" == "zsh" ]]; then
                echo "starship|zsh" >>"${scrDir}/install_pkg.lst"
            elif [[ "${myShell}" == "fish" ]]; then
                echo "starship|fish" >>"${scrDir}/install_pkg.lst"
            else
                # For bash, use starship-git from AUR
                if chk_list "aurhlpr" "${aurList[@]}"; then
                    echo "starship-git" >>"${scrDir}/install_pkg.lst"
                else
                    print_log -sec "prompt" -warn "No AUR helper" "Skipping starship installation"
                    print_log -sec "prompt" -stat "info" "Install manually later: yay -S starship-git"
                fi
            fi
            print_log -sec "prompt" -stat "selected" "starship"
            ;;
        3|s|S|skip|SKIP)
            export myPrompt=""
            print_log -sec "prompt" -stat "selected" "None (skipping prompt theming)"
            ;;
        *)
            print_log -sec "prompt" -warn "Defaulting to oh-my-posh"
            export myPrompt="oh-my-posh"
            if chk_list "aurhlpr" "${aurList[@]}"; then
                echo "oh-my-posh" >>"${scrDir}/install_pkg.lst"
            fi
            ;;
        esac
    elif pkg_installed oh-my-posh; then
        export myPrompt="oh-my-posh"
        print_log -g "[PROMPT] " "oh-my-posh already installed"
    elif pkg_installed starship || pkg_installed starship-git; then
        export myPrompt="starship"
        print_log -g "[PROMPT] " "starship already installed"
    fi

    # Hyde CLI installation prompt
    if ! chk_list "hydeCliInstalled" "hyde-cli" "hyde-cli-git"; then
        print_log -c "Hyde CLI :: "
        print_log -sec "1" " Yes - Install Hyde CLI (provides 'Hyde' command with structured subcommands)"
        print_log -sec "2" " No - Use hyde-shell only (default, minimal)"
        prompt_timer 120 "Enter option number [default: 2] | s to skip "

        case "${PROMPT_INPUT}" in
        1|y|Y|yes|YES)
            # Check if AUR helper is available for hyde-cli-git
            if chk_list "aurhlpr" "${aurList[@]}"; then
                print_log -sec "Hyde CLI" -stat "selected" "hyde-cli-git (will install via AUR)"
                echo "hyde-cli-git" >>"${scrDir}/install_pkg.lst"
            else
                print_log -sec "Hyde CLI" -warn "No AUR helper" "Skipping Hyde CLI installation"
                print_log -sec "Hyde CLI" -stat "info" "Install manually later: yay -S hyde-cli-git"
            fi
            ;;
        2|n|N|no|NO|s|S|skip|SKIP|"")
            print_log -sec "Hyde CLI" -stat "selected" "Skipped (using hyde-shell only)"
            print_log -sec "Hyde CLI" -stat "info" "Install later: yay -S hyde-cli-git"
            ;;
        *)
            print_log -sec "Hyde CLI" -warn "Defaulting to" "No (hyde-shell only)"
            print_log -sec "Hyde CLI" -stat "info" "Install later: yay -S hyde-cli-git"
            ;;
        esac
    fi

    if ! grep -q "^#user packages" "${scrDir}/install_pkg.lst"; then
        print_log -sec "pkg" -crit "No user packages found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}/install.sh"
        exit 1
    fi

    #--------------------------------#
    # install packages from the list #
    #--------------------------------#
    "${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
fi

#---------------------------#
# restore my custom configs #
#---------------------------#
if [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"

             _           _
 ___ ___ ___| |_ ___ ___|_|___ ___
|  _| -_|_ -|  _| . |  _| |   | . |
|_| |___|___|_| |___|_| |_|_|_|_  |
                              |___|

EOF

    if [ "${flg_DryRun}" -ne 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl keyword misc:disable_autoreload 1 -q
    fi

    "${scrDir}/restore_fnt.sh"
    "${scrDir}/restore_cfg.sh"
    "${scrDir}/restore_thm.sh"
    print_log -g "[generate] " "cache ::" "Wallpapers..."
    if [ "${flg_DryRun}" -ne 1 ]; then
        export PATH="$HOME/.local/lib/hyde:$HOME/.local/bin:${PATH}"
        "$HOME/.local/lib/hyde/swwwallcache.sh" -t ""
        "$HOME/.local/lib/hyde/theme.switch.sh" -q || true
        "$HOME/.local/lib/hyde/waybar.py" --update || true
        echo "[install] reload :: Hyprland"
    fi

fi

#---------------------#
# post-install script #
#---------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"

             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${scrDir}/install_pst.sh"
fi


#---------------------------#
# run migrations            #
#---------------------------#
if [ ${flg_Restore} -eq 1 ]; then

# migrationDir="$(realpath "$(dirname "$(realpath "$0")")/../migrations")"
migrationDir="${scrDir}/migrations"

if [ ! -d "${migrationDir}" ]; then
    print_log -warn "Migrations" "Directory not found: ${migrationDir}"
fi

echo "Running migrations from: ${migrationDir}"

if [ -d "${migrationDir}" ] && find "${migrationDir}" -type f | grep -q .; then
    migrationFile=$(find "${migrationDir}" -maxdepth 1 -type f -printf '%f\n' | sort -r | head -n 1)

    if [[ -n "${migrationFile}" && -f "${migrationDir}/${migrationFile}" ]]; then
        echo "Found migration file: ${migrationFile}"
        sh "${migrationDir}/${migrationFile}"
    else
        echo "No migration file found in ${migrationDir}. Skipping migrations."
    fi
fi

fi

#------------------------#
# enable system services #
#------------------------#
if [ ${flg_Service} -eq 1 ]; then
    cat <<"EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

    "${scrDir}/restore_svc.sh"
fi

if [ $flg_Install -eq 1 ]; then
    echo ""
    print_log -g "Installation" " :: " "COMPLETED!"
fi
print_log -b "Log" " :: " -y "View logs at ${cacheDir}/logs/${HYDE_LOG}"
if [ $flg_Install -eq 1 ] ||
    [ $flg_Restore -eq 1 ] ||
    [ $flg_Service -eq 1 ] &&
    [ $flg_DryRun -ne 1 ]; then

    if [[ -z "${HYPRLAND_CONFIG:-}" ]] || [[ ! -f "${HYPRLAND_CONFIG}" ]]; then
        print_log -warn "Hyprland config not found! Might be a new install or upgrade."
        print_log -warn "Please reboot the system to apply new changes."
    fi

    print_log -stat "HyDE" "It is not recommended to use newly installed or upgraded HyDE without rebooting the system. Do you want to reboot the system? (y/N)"
    read -r answer

    if [[ "$answer" == [Yy] ]]; then
        echo "Rebooting system"
        systemctl reboot
    else
        echo "The system will not reboot"
    fi
fi
