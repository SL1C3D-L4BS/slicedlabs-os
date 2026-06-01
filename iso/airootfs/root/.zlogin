# SlicedLabs OS live ISO — run the first-boot choreography once, on the root login.
if [[ -x /root/slicedlabs-firstboot.sh ]]; then
    /root/slicedlabs-firstboot.sh
fi
