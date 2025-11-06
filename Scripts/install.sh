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

    #--------------------------------#
    # add gpu drivers to the list    #
    #--------------------------------#
    print_log -sec "GPU" -stat "detecting" "graphics hardware"
    
    # Detect and add GPU drivers
    if [[ ${flg_Nvidia} -eq 1 ]]; then
        # Add GPU drivers to package list
        add_gpu_drivers_to_package_list "${scrDir}/install_pkg.lst" 1 1
        print_log -sec "GPU" -stat "added" "NVIDIA and AMD drivers to package list"
    else
        # Only add AMD/Intel drivers (skip NVIDIA)
        add_gpu_drivers_to_package_list "${scrDir}/install_pkg.lst" 0 1
        print_log -sec "GPU" -stat "added" "AMD/Intel drivers (NVIDIA ignored)"
    fi
    
    # Show GPU detection results
    print_gpu_info

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
    echo ""
    if ! chk_list "aurhlpr" "${aurList[@]}"; then
        print_log -c "\nAUR Helpers :: "
        aurList+=("yay-bin" "paru-bin") # Add this here instead of in global_fn.sh
        for i in "${!aurList[@]}"; do
            print_log -sec "$((i + 1))" " ${aurList[$i]} "
        done

        prompt_timer 120 "Enter option number [default: yay-bin] | s to skip "

        case "${PROMPT_INPUT}" in
        1) export getAur="yay" ;;
        2) export getAur="paru" ;;
        3) export getAur="yay-bin" ;;
        4) export getAur="paru-bin" ;;
        s|S|skip|SKIP)
            print_log -sec "AUR" -warn "Skipped" "No AUR helper will be installed"
            export getAur=""
            ;;
        *)
            print_log -sec "AUR" -warn "Defaulting to yay-bin"
            print_log -sec "AUR" -stat "default" "yay-bin"
            export getAur="yay-bin"
            ;;
        esac
        
        # Only add to install list if user didn't skip
        if [[ -n "$getAur" ]]; then
            print_log -sec "AUR" -stat "selected" "${getAur}"
        fi
    fi

    # Shell selection with bash, zsh, fish options
    if ! chk_list "myShell" "${shlList[@]}"; then
        print_log -c "Shell :: "
        for i in "${!shlList[@]}"; do
            print_log -sec "$((i + 1))" " ${shlList[$i]} "
        done
        prompt_timer 120 "Enter option number [default: bash] | s to skip "

        case "${PROMPT_INPUT}" in
        1) export myShell="bash" ;;
        2) export myShell="zsh" ;;
        3) export myShell="fish" ;;
        s|S|skip|SKIP)
            print_log -sec "shell" -warn "Skipped" "Using current shell, no additional shell will be installed"
            export myShell="$(basename "$SHELL")"
            ;;
        *)
            print_log -sec "shell" -warn "Defaulting to bash"
            export myShell="bash"
            ;;
        esac
        
        # Add to package list and report
        echo "${myShell}" >>"${scrDir}/install_pkg.lst"
        print_log -sec "shell" -stat "selected" "${myShell}"
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
