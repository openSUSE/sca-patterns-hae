# Copyright (C) 2013 SUSE LLC
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

# norootforbuild
# neededforbuild

%define sca_common sca
%define patdirbase /usr/lib/%{sca_common}
%define patdir %{patdirbase}/patterns
%define patuser root
%define patgrp root
%define mode 544
%define category HAE

Name:         sca-patterns-hae
Summary:      Supportconfig Analysis Patterns for HAE
URL:          https://bitbucket.org/g23guy/sca-patterns-hae
Group:        Documentation/SuSE
License:      GPL-2.0
Autoreqprov:  on
Version:      1.3
Release:      1
Source:       %{name}-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}
Buildarch:    noarch
Requires:     sca-patterns-base

%description
Supportconfig Analysis (SCA) appliance patterns to identify known
issues relating to all versions of High Availability Extension (HAE)
clustering

Authors:
--------
    Jason Record <jrecord@suse.com>

%prep
%setup -q

%build

%install
pwd;ls -la
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}
install -m %{mode} patterns/%{category}/* $RPM_BUILD_ROOT/%{patdir}/%{category}

%files
%defattr(-,%{patuser},%{patgrp})
%dir %{patdirbase}
%dir %{patdir}
%dir %{patdir}/%{category}
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Thu Jan 16 2014 jrecord@suse.com
- relocated files according to FHS

* Wed Dec 20 2013 jrecord@suse.com
- separated as individual RPM package

