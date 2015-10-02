function restart-dnsmasq() {
    printf "\033[1;31msudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist\n\033[0m"
    sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
    printf "\033[1;32msudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist\n\033[0m"
    sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
    printf "Waiting..."
    for x in `seq 4`; do
        sleep 1;
        printf "."
    done
    echo
    echo "==========================================="
    printf "\033[1;33mLast 20 lines of DNSMasq logs:\n\033[0m"
    sudo tail -20 /var/log/dnsmasq.log
}
