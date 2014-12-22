checkfile="/var/vagrant_has_dropped_data"
if [ ! -f $checkfile ]; then
	cp /vagrant/data/* /opt/. -R
	touch $checkfile
fi