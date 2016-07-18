#!/bin/bash
set -e
tag=$1
slave_id=$2
echo "tag=${tag} and slave_id=${slave_id}"

sudo service mesos-slave stop
# Add grouping informaiton
sudo mkdir -p /etc/mesos-slave/attributes/
echo ${tag} | sudo tee /etc/mesos-slave/attributes/group
echo ${tag}_${slave_id} | sudo tee /etc/mesos-slave/attributes/slave_id
# add additional port resources
echo "ports:[2000-32000]" | sudo tee /etc/mesos-slave/resources
# Linux by default uses port 23768-61000
# if you decide to use any ports in that range you can modify the following
# Tell linux to not use these ports (Add the following to /etc/sysctl.conf file)
# net.ipv4.ip_local_port_range ="40001 60000"

# Tell mesos-slave to cleanup the work area frequently (Otherwise it will fill up)
echo "60mins" | sudo tee /etc/mesos-slave/gc_delay

# Optionally you can change the mesos work directory from /tmp
echo "/opt/mesos" | sudo tee /etc/mesos-slave/work_dir

# Increase max number of memory map areas for processes
# Full doc
# https://www.kernel.org/doc/Documentation/sysctl/vm.txt
echo "600000" | sudo tee /proc/sys/vm/max_map_count

# Also increase max pid
# For more info "man proc" and search "pid_max"
echo "200000" | sudo tee /proc/sys/kernel/pid_max

# Increase FD limits
# Add to the end of /etc/security/limits.conf
echo "
* soft     nproc          65535
* hard     nproc          65535
* soft     nofile         65535
* hard     nofile         65535
root soft     nofile         65535
root hard     nofile         65535" | sudo tee -a /etc/security/limits.conf

# All the old workloads will need to be cleaned up as the slave properties have changed
# only do this if you are sure about deleting old workloads
sudo rm -f /tmp/mesos/meta/slaves/latest
# start the slave
sudo service mesos-slave start
