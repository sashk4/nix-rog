{ config, lib, pkgs, zen-browser, nixos-hardware, ... }:

{
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.asus-zephyrus-ga402
  ];  

  # ── Kernel ──────────────────────────────────────────────────────────────────
  # Latest kernel recommended by asus-linux for GA402RJ (6.10+ for best asusd support)
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fwupd.enable = true;
  
  boot.kernelModules = [
    "kvm-amd"    # AMD virtualisation
    "iwlwifi"
    "iwlmvm"
    "mac80211"
    "cfg80211"
    "ptp"
    "asus_wmi"
    "hid_asus"
    "ntsync"
  ];

  # GA402RJ-specific boot params
  boot.kernelParams = [
    "acpi_osi=Linux"
    "amd_pstate=active"    # AMD P-state driver for better perf/efficiency
    "amdgpu.sg_display=0"  # fixes occasional display flicker on RDNA2
    "quiet"
    "splash"
  ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "xhci_hcd" # usb
    "nvme"
    "usb_storage"
    "sd_mod" # nvme / external usb storage
    "rtsx_pci_sdmmc" # sdcard
    "usbnet"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ───────────────────────────────────────────────────────────────
  networking.hostName = "nix-rog";
  networking.networkmanager.enable = true;

  # ── Time / Locale ────────────────────────────────────────────────────────────
  time.timeZone = "America/New_York";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # ── Display / Wayland ────────────────────────────────────────────────────────
  programs.hyprland.enable = true;

  # greetd + tuigreet as login manager (lightweight, works well with niri)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      user = "greeter";
    };
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # ── Audio ────────────────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # ── ASUS ROG hardware ────────────────────────────────────────────────────────
  # asusd handles fan curves, keyboard backlight, power profiles, etc.
  # ROG Control Center GUI is bundled with the asusd module automatically.
  services.asusd.enable = true;

  # supergfxctl for GPU switching (integrated <-> dGPU)
  services.supergfxd.enable = true;
  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  # power-profiles-daemon integrates with asusd profile switching
  services.power-profiles-daemon.enable = false;

  # ── AMD GPU ──────────────────────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.clr.icd
    ];
  };

  hardware.cpu.amd.ryzen-smu.enable = true;

  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland,x11,windows";
    XDG_SESSION_TYPE = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland,x11";
    BRAVE_ENABLE_WAYLAND_IME = "1";
  };

  # ── Gaming ───────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraPkgs = pkgs': with pkgs'; [
          libXcursor libXi libXinerama libXScrnSaver
        ];
    };
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };

  # ── Packages ─────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;
  programs.nix-ld.enable =true;
  programs.fish.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true; # Set true if using Fish
  };

  environment.systemPackages = with pkgs; [
    # ── Editors & terminal stuff ──
    vim
    nodejs
    ripgrep
    neovim
    ghostty
    alacritty
    pywal16
    eza
    rustup
    deno
    helix
    gnumake
    bun
    yt-dlp
    fzf

    # ── Browsers ──
    chromium
    librewolf
    zen-browser.packages.x86_64-linux.default

    # ── Dev basics ──
    wget
    curl
    git
    gh
    tree
    cutter

    # ── Communication ──
    vesktop
    telegram-desktop

    # ── Library ──
    calibre

    # ── Gaming ──
    protonup-qt
    gamescope
    mangohud
    lutris
    prismlauncher

    # ── ASUS / hardware tools ──
    asusctl
    supergfxctl

    # ── Wayland desktop essentials ──
    waybar
    xwayland
    obs-studio
    mpv
    cairo
    awww
    nwg-look
    fuzzel
    mako
    swaylock
    rofi
    swayidle
    swaybg
    wl-clipboard
    grim
    slurp
    brightnessctl
    bibata-cursors
    playerctl
    xwayland-satellite
    kdePackages.dolphin
    kdePackages.qtsvg
    kdePackages.kio-extras
    kdePackages.kio-fuse
    wireguard-tools
    jmtpfs
    kdePackages.kdenlive
    bitwig-studio

    # ── System utilities ──
    networkmanagerapplet
    ffmpeg
    pavucontrol
    easyeffects
    noisetorch
    xauth
    usbutils
    pciutils
    htop
    ripgrep
    fd
    unzip
    cmake
    ninja
    gcc
    pkg-config
  ];

  # ── Fonts ────────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # ── User ─────────────────────────────────────────────────────────────────────
  users.users.sashk4 = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "audio" "networkmanager" "video" "input" "gamemode" ];
    packages = with pkgs; [
      tree
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # ── Nix settings ─────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # system.copySystemConfiguration = true;

  system.stateVersion = "25.11"; # Did you read the comment?

}

