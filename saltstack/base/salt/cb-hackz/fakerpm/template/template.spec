# Do not change this!
# For the sake of all people working on a support.
Name: %{fake_name}

Version: %{fake_version}
Release: %{fake_release}
License: CC0

Summary: Faked provides of %{fake_provides}

Provides: %{fake_provides}
Provides: %{fake_name}
%if "%{?fake_requires}" != ""
Requires: %{fake_requires}
%endif
BuildArch: noarch

%description
This package is empty. It has been created to put fake entry in rpmdb.

%files
#intentionaly empty

%changelog
#intentionaly empty
