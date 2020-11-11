#
# Make sure Ruby and Rake got installed
# Created by xing
#

if [ -x "$(command -v rake)" ]
then
  return
fi

if_su=''
if [ "$(id -u)" != '0' ]
then
  if_su='sudo'
fi

package_manager=""
cmd_install=""
opt_yes=""

if [ -x "$(command -v apt-get)" ]
then
  package_manager='apt'
  cmd_install='install'
  opt_yes='-y'
elif [ -x "$(command -v yum)" ]
then
  package_manager='yum'
  cmd_install='install'
  opt_yes='-y'
elif [ -x "$(command -v apk)" ]
then
  package_manager='apk'
  cmd_install='add'
  opt_yes=''
elif [ -x "$(command -v brew)" ]
then
  if_su=''
  package_manager='brew'
  cmd_install='install'
  opt_yes=''
else
  echo 'Unknown package manager!'
  return $?
fi

cmd_to_run="$if_su $package_manager $cmd_install $opt_yes rake"
echo "$cmd_to_run"
eval "$cmd_to_run"

rake --version
