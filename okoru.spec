Name:           okoru
Version:        1.0.0
Release:        1%{?dist}
Summary:        Bash logging library with colored, leveled output
License:        MIT
BuildArch:      noarch
Requires:       bash

Source0:        okoru.sh

%description
Okoru is a bash shell library providing colored, leveled logging functions
(debug, info, warn, error, ok) for use in shell scripts. Source it at the
top of any script to get consistent, timestamped log output with optional
log file rotation.

%install
install -Dm644 %{SOURCE0} %{buildroot}%{_datadir}/okoru/okoru.sh

%files
%{_datadir}/okoru/okoru.sh

%changelog
* Mon Jun 15 2026 Matan Horovitz - 1.0.0-1
- Initial package
