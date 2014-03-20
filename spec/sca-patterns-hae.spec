# spec file for package sca-patterns-hae
#
# Copyright (C) 2014 SUSE LLC
#
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
%define category SLE
%define fdupes

Name:         sca-patterns-hae
Summary:      Supportconfig Analysis Patterns for HAE
URL:          https://bitbucket.org/g23guy/sca-patterns-hae
Group:        System/Monitoring
License:      GPL-2.0
Autoreqprov:  on
Version:      1.3
Release:      6
Source:       %{name}-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}
BuildRequires: fdupes
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
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/sle10all
install -d $RPM_BUILD_ROOT/%{patdir}/%{category}/sle11all
install -d $RPM_BUILD_ROOT/usr/share/doc/packages/%{sca_common}
install -m 444 patterns/COPYING.GPLv2 $RPM_BUILD_ROOT/usr/share/doc/packages/%{sca_common}
install -m %{mode} patterns/HAE/* $RPM_BUILD_ROOT/%{patdir}/%{category}/sle10all
install -m %{mode} patterns/HAE/* $RPM_BUILD_ROOT/%{patdir}/%{category}/sle11all
%fdupes %{buildroot}

%files
%defattr(-,%{patuser},%{patgrp})
%dir %{patdirbase}
%dir %{patdir}
%dir %{patdir}/%{category}
%dir %{patdir}/%{category}/sle10all
%dir %{patdir}/%{category}/sle11all
%dir /usr/share/doc/packages/%{sca_common}
%doc %attr(-,root,root) /usr/share/doc/packages/%{sca_common}/*
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/sle10all/*
%attr(%{mode},%{patuser},%{patgrp}) %{patdir}/%{category}/sle11all/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog

