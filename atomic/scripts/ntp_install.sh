if ! `rpm -q --quiet chrony` && ! `rpm -q --quiet ntp-`; then
# Function to install packages on RHEL, Fedora, Debian, and possibly other systems.
#
# Example Call(s):
#
#     package_install aide
#
function package_install {

# Load function arguments into local variables
local package="$1"

# Check sanity of the input
if [ $# -ne "1" ]
then
  echo "Usage: package_install 'package_name'"
  echo "Aborting."
  exit 1
fi

if which dnf ; then
  if ! rpm -q --quiet "$package"; then
    dnf install -y "$package"
  fi
elif which yum ; then
  if ! rpm -q --quiet "$package"; then
    yum install -y "$package"
  fi
elif which apt-get ; then
  apt-get install -y "$package"
else
  echo "Failed to detect available packaging system, tried dnf, yum and apt-get!"
  echo "Aborting."
  exit 1
fi

}

  package_install chrony
  service_command enable chronyd
elif `rpm -q --quiet chrony`; then
  if ! [ `/usr/sbin/pidof ntpd` ] ; then
# Function to enable/disable and start/stop services on RHEL and Fedora systems.
#
# Example Call(s):
#
#     service_command enable bluetooth
#     service_command disable bluetooth.service
#
#     Using xinetd:
#     service_command disable rsh.socket xinetd=rsh
#
function service_command {

# Load function arguments into local variables
local service_state=$1
local service=$2
local xinetd=$(echo $3 | cut -d'=' -f2)

# Check sanity of the input
if [ $# -lt "2" ]
then
  echo "Usage: service_command 'enable/disable' 'service_name.service'"
  echo
  echo "To enable or disable xinetd services add \'xinetd=service_name\'"
  echo "as the last argument"  
  echo "Aborting."
  exit 1
fi

# If systemctl is installed, use systemctl command; otherwise, use the service/chkconfig commands
if [ -f "/usr/bin/systemctl" ] ; then
  service_util="/usr/bin/systemctl"
else
  service_util="/sbin/service"
  chkconfig_util="/sbin/chkconfig"
fi

# If disable is not specified in arg1, set variables to enable services.
# Otherwise, variables are to be set to disable services.
if [ "$service_state" != 'disable' ] ; then
  service_state="enable"
  service_operation="start"
  chkconfig_state="on"
else
  service_state="disable"
  service_operation="stop"
  chkconfig_state="off"
fi

# If chkconfig_util is not empty, use chkconfig/service commands.
if [ "x$chkconfig_util" != x ] ; then
  $service_util $service $service_operation
  $chkconfig_util --level 0123456 $service $chkconfig_state
else
  $service_util $service_operation $service
  $service_util $service_state $service
  # The service may not be running because it has been started and failed,
  # so let's reset the state so OVAL checks pass.
  # Service should be 'inactive', not 'failed' after reboot though.
  $service_util reset-failed $service
fi

# Test if local variable xinetd is empty using non-bashism.
# If empty, then xinetd is not being used.
if [ "x$xinetd" != x ] ; then
  grep -qi disable /etc/xinetd.d/$xinetd && \

  if [ "$service_operation" = 'disable' ] ; then
    sed -i "s/disable.*/disable         = no/gI" /etc/xinetd.d/$xinetd
  else
    sed -i "s/disable.*/disable         = yes/gI" /etc/xinetd.d/$xinetd
  fi
fi

}

    service_command enable chronyd
  fi
else
# Function to enable/disable and start/stop services on RHEL and Fedora systems.
#
# Example Call(s):
#
#     service_command enable bluetooth
#     service_command disable bluetooth.service
#
#     Using xinetd:
#     service_command disable rsh.socket xinetd=rsh
#
function service_command {

# Load function arguments into local variables
local service_state=$1
local service=$2
local xinetd=$(echo $3 | cut -d'=' -f2)

# Check sanity of the input
if [ $# -lt "2" ]
then
  echo "Usage: service_command 'enable/disable' 'service_name.service'"
  echo
  echo "To enable or disable xinetd services add \'xinetd=service_name\'"
  echo "as the last argument"  
  echo "Aborting."
  exit 1
fi

# If systemctl is installed, use systemctl command; otherwise, use the service/chkconfig commands
if [ -f "/usr/bin/systemctl" ] ; then
  service_util="/usr/bin/systemctl"
else
  service_util="/sbin/service"
  chkconfig_util="/sbin/chkconfig"
fi

# If disable is not specified in arg1, set variables to enable services.
# Otherwise, variables are to be set to disable services.
if [ "$service_state" != 'disable' ] ; then
  service_state="enable"
  service_operation="start"
  chkconfig_state="on"
else
  service_state="disable"
  service_operation="stop"
  chkconfig_state="off"
fi

# If chkconfig_util is not empty, use chkconfig/service commands.
if [ "x$chkconfig_util" != x ] ; then
  $service_util $service $service_operation
  $chkconfig_util --level 0123456 $service $chkconfig_state
else
  $service_util $service_operation $service
  $service_util $service_state $service
  # The service may not be running because it has been started and failed,
  # so let's reset the state so OVAL checks pass.
  # Service should be 'inactive', not 'failed' after reboot though.
  $service_util reset-failed $service
fi

# Test if local variable xinetd is empty using non-bashism.
# If empty, then xinetd is not being used.
if [ "x$xinetd" != x ] ; then
  grep -qi disable /etc/xinetd.d/$xinetd && \

  if [ "$service_operation" = 'disable' ] ; then
    sed -i "s/disable.*/disable         = no/gI" /etc/xinetd.d/$xinetd
  else
    sed -i "s/disable.*/disable         = yes/gI" /etc/xinetd.d/$xinetd
  fi
fi

}

  service_command enable ntpd
fi
