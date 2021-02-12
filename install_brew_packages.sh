run() {
    # Run the compilation process.
    # cd $PLATFORM_CACHE_DIR || exit 1;

    # if .linuxbrew folder exists, we can assume everything is installed
    cache_folder="${PLATFORM_CACHE_DIR}/.linuxbrew"
    cache_file="$cache_folder/cached_components"
    echo "Cache folder $cache_folder"
    echo "Cache file $cache_file"
    echo "Current folder $(pwd)"
    # check if we have brew installed
    if [ ! -f "$cache_folder/bin/brew" ]; 
    then
        install_brew
    else
        copy_lib_from_cache
    fi
    

    load_brew
    
    # Check to see if the cache file exists
    if [ ! -f ${cache_file} ]; 
    then 
        echo "" > $cache_file
    fi
    
    # check if cache_contents actually matches what we want
    cache_contents=$(<"$cache_file")
    if [[ "$cache_contents" != "$@" ]]; then
        # Not the same components, so reinstall
        install_components $@
        copy_lib_to_cache $@
        echo "$@" > $cache_file
    fi
    
    
    # Always write the .profile file, so that we can be sure that all bins are immediately ready for use
    write_profile
    
}

copy_lib_to_cache() {
    echo "Copy to cache..."
    cp -Rf $PLATFORM_APP_DIR/.linuxbrew $PLATFORM_CACHE_DIR
}

copy_lib_from_cache() {
    echo "Copy from cache..."
    cp -Rf $PLATFORM_CACHE_DIR/.linuxbrew $PLATFORM_APP_DIR
}

install_brew() {
    echo "Installing homebrew"
    mkdir -p /app/.linuxbrew

    echo "Downloading tarball from master repository"
    curl -SsL https://github.com/Homebrew/brew/tarball/master -o brew.tar.gz
    
    echo "Unpacking into .linuxbrew folder"
    tar xzf brew.tar.gz --strip-components 1 -C /app/.linuxbrew/
    rm brew.tar.gz
    
    copy_lib_to_cache
}

load_brew() {
    eval $(/app/.linuxbrew/bin/brew shellenv)
    brew analytics off
}

install_components() {
  components_to_install="$@"
  echo "Installing components: '$components_to_install'"
  for f in $components_to_install
  do
		  echo "Installing component: '$f'"
      install_component $f
  done
}

install_component() {
    brew install $1
}

write_profile() {
  touch /app/.profile
  echo 'export HOMEBREW_CELLAR="/app/.linuxbrew/Cellar";' >> /app/.profile
  echo 'export HOMEBREW_REPOSITORY="/app/.linuxbrew/Homebrew";' >> /app/.profile
  echo 'export PATH="/app/.linuxbrew/bin:/app/.linuxbrew/sbin${PATH+:$PATH}";' >> /app/.profile
  echo 'export MANPATH="/app/.linuxbrew/share/man${MANPATH+:$MANPATH}:";' >> /app/.profile
  echo 'export INFOPATH="/app/.linuxbrew/share/info:${INFOPATH:-}";' >> /app/.profile
}

echo "Installing: $@"
run $@



