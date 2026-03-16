{ config, lib, pkgs, zen-browser, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # ── Kernel ──────────────────────────────────────────────────────────────────
  # Latest kernel recommended by asus-linux for GA402RJ (6.10+ for best asusd support)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelModules = [
    "kvm-amd"    # AMD virtualisation
    "acpi_call"  # needed by some power tools
  ];

  # GA402RJ-specific boot params
  boot.kernelParams = [
    "amd_pstate=active"    # AMD P-state driver for better perf/efficiency
    "amdgpu.sg_display=0"  # fixes occasional display flicker on RDNA2
    "quiet"
    "splash"
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
  programs.niri.enable = true;

  # greetd + tuigreet as login manager (lightweight, works well with niri)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
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
  services.power-profiles-daemon.enable = true;

  # ── AMD GPU ──────────────────────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.clr.icd
    ];
  };

  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
  };

  # ── Gaming ───────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # ── Packages ─────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true; # Set true if using Fish
  };

  environment.systemPackages = with pkgs; [
    # ── Editors & terminal stuff ──
    vim
    neovim
    ghostty
    alacritty
    eza
    rustup
    deno

    # ── Browsers ──
    chromium
    zen-browser.packages.x86_64-linux.default
    # NOTE: Zen browser is not in nixpkgs yet.
    # To add it, convert this to a flake and add:
    #   inputs.zen-browser.url = "github:youwen5/zen-browser-flake";
    # then add to packages: inputs.zen-browser.packages.x86_64-linux.default

    # ── Dev basics ──
    wget
    curl
    git
    gh
    tree

    # ── Gaming ──
    protonup-qt
    mangohud
    lutris

    # ── ASUS / hardware tools ──
    asusctl
    supergfxctl

    # ── Wayland desktop essentials ──
    waybar
    swww
    fuzzel
    mako
    swaylock
    swayidle
    swaybg
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    xwayland-satellite

    # ── System utilities ──
    networkmanagerapplet
    pavucontrol
    usbutils
    pciutils
    htop
    ripgrep
    fd
    unzip
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
    extraGroups = [ "wheel" "networkmanager" "video" "input" "gamemode" ];
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

