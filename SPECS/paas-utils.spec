%define _topdir /usr/src/rpmbuild
%define prefix /usr/local
%define sources /usr/local/paas-libs/paas
Name:           paas-libs
Version:        0.2
Release:        1
%define buildroot %{_topdir}/%{name}-%{version}
Summary:        Entity providing necessary services to processes

Group:          Applications/Paas
BuildArch:			noarch
License:        Apache
URL:            http://worldline.com
BuildRoot:      %{buildroot}
Source0:		/usr/local/paas-libs/paas
Prefix:		%{prefix}

#BuildRequires:  
Requires:				openshift-origin-broker >= 1.15.1
Requires:				ruby193-rubygems >= 1.8.24
Requires:				ruby193-rubygem-dnsruby >= 1.53
Requires:				ruby193-mcollective-common >= 2.2.3
Requires: 			rubygem-openshift-origin-msg-broker-mcollective >= 1.15
Requires:				ruby193-rubygem-sqlite3 >= 1.3.6
Requires:				ruby-sqlite3 >= 1.3.3
Requires:				ruby193-rubygem-json_pure >= 1.7.3
Requires:				ruby193-rubygem-json >= 1.7.3
Requires:				ruby193-rubygem-rest-client >= 1.6.1

%description
Paas: Entity providing necessary services to processes

%prep
rm -rf %{name}
mkdir %{name}
%__cp -Rp %{sources} %{name}

%install
mkdir -p ${RPM_BUILD_ROOT}/%{prefix}
%__cp -Rp %{name}/* ${RPM_BUILD_ROOT}/%{prefix}

%clean
# rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/local/paas/lib/broker.rb
/usr/local/paas/lib/config.rb
/usr/local/paas/lib/node.rb
/usr/local/paas/lib/rproxy.rb
/usr/local/paas/lib/paasexceptions.rb
%config
/usr/local/paas/etc/configProxy.conf

%post
if ! [ -f /etc/paas/configProxy.conf ]; then ln -s /usr/local/paas/etc/configProxy.conf /etc/paas/configProxy.conf; fi

%postun

%changelog
* Mon Oct 10 2013 - 0.2 - a186643
- Clean version to update on github
* Mon Jul 31 2013 - 0.1.1 - a186643
- Version corrigée après install sur version nightly repo git 
* Mon Jun 30 2013 - 0.1 - a186643
- Version initiale

