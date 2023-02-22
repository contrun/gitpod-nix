FROM gitpod/workspace-base

USER root

# Install Nix
RUN addgroup --system nixbld \
  && adduser gitpod nixbld \
  && for i in $(seq 1 30); do useradd -ms /bin/bash nixbld$i &&  adduser nixbld$i nixbld; done \
  && mkdir -m 0755 /nix && chown gitpod /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf \
  && echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf
  
# Install Nix
CMD /bin/bash -l
USER gitpod
ENV USER gitpod
WORKDIR /home/gitpod

RUN touch .bash_profile \
 && curl -L https://github.com/nix-community/nix-unstable-installer/releases/download/nix-2.14.0pre20230127_ccaadc9/install | sh

RUN echo '. /home/gitpod/.nix-profile/etc/profile.d/nix.sh' >> .bashrc
RUN mkdir -p .config/nixpkgs && echo '{ allowUnfree = true; }' >> .config/nixpkgs/config.nix

# Install cachix
RUN . .nix-profile/etc/profile.d/nix.sh \
  && nix profile install --impure 'nixpkgs#cachix' \
  && cachix use cachix \
  && cachix use contrun

# Install flox
RUN . .nix-profile/etc/profile.d/nix.sh \
  && nix profile install --accept-flake-config --impure 'github:flox/floxpkgs#flox.fromCatalog'

# Install git
RUN . .nix-profile/etc/profile.d/nix.sh \
  && nix profile install --impure 'nixpkgs#git' 'nixpkgs#git-lfs'

# Install direnv
RUN . .nix-profile/etc/profile.d/nix.sh \
  && nix profile install --impure 'nixpkgs#direnv' \
  && direnv hook bash >> .bashrc \
  && echo 'direnv allow' >> .bashrc