Name:       harbour-fiatmargo
Summary:    Prepare a photo for a Sailfish ambience
Version:    1.0.0
Release:    1
Group:      Applications/Multimedia
License:    MIT
URL:        https://github.com/munksh/FiatMargo
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Gui)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

# NOTE ON THIS FILE -- kept ABOVE %%description on purpose.
#
# 1. The SailfishOS:Chum metadata block must be the LAST contiguous paragraph
#    of %%description, with no blank lines and NO COMMENTS inside it. These
#    notes used to sit directly under %%description, which would now break the
#    parsing. Do not move them back.
#
# 2. Do NOT use %%qtc_qmake5 or %%qtc_make. Those macros are undefined on this
#    target. rpm passes the line through verbatim, bash reads a leading percent
#    sign as a job specification, and you get "fg: no job control" -- a warning
#    only, so the package still builds, but the build step never actually runs.
#    %%qmake5_install is undefined too; use the plain make install form below.
#
# 3. rpm expands macros INSIDE COMMENTS. Every percent sign in these notes is
#    doubled for that reason, including the ones in prose. A bare install macro
#    written in a sentence expands to the real thing, drags %%debug_package in
#    with it, and the debuginfo subpackage gets declared twice:
#        error: line NN: %%package debuginfo: package NAME-debuginfo already exists
#
# 4. Do NOT add Requires: for plugins that ship with the OS.
#    nemo-qml-plugin-configuration does not exist as a package name and the
#    install dies with "Paketet hittades ej". Nemo.Configuration and
#    Sailfish.Pickers are both already there.

%description
Sailfish crops a photo twice on its way to becoming an ambience: once to a
square, then again to a narrow strip the height of the screen. fiat margo
does the opposite. It pads the photo out so that everything the crop throws
away is fill rather than photograph, and the picture you framed is the
picture you see.

The fill is taken from the colours already present along the edges of your
own photo, so it reads as part of the image rather than as a border.

%if 0%{?_chum}
Title: fiat margo
Type: desktop-application
DeveloperName: Caesar Prometheus Ivarsson
Categories:
 - Graphics
 - Utility
Custom:
  Repo: https://github.com/munksh/FiatMargo
PackageIcon: https://munkstolen.se/SFOS/fiat-margo/harbour-fiatmargo.png
Screenshots:
 - https://munkstolen.se/SFOS/fiat-margo/fiat-margo1.png
 - https://munkstolen.se/SFOS/fiat-margo/fiat-margo2.png
 - https://munkstolen.se/SFOS/fiat-margo/fiat-margo3.png
Links:
  Homepage: https://munkstolen.se
  Help: https://github.com/munksh/FiatMargo/discussions
  Bugtracker: https://github.com/munksh/FiatMargo/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install INSTALL_ROOT=%{buildroot}

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
  %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
