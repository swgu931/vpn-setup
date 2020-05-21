# Execution Docker
#!/bin/bash

docker run --rm -itd \
--hostname vpn-host-1 \
--net host \
--name vpn-host-1 \
tiryoh/ros2:dashing


docker run --rm -itd \
--hostname vpn-host-2 \
--net host \
--name vpn-host-2 \
tiryoh/ros2:dashing

docker inspect vpn-host-1 | grep IPAddress
docker inspect vpn-host-2 | grep IPAddress


