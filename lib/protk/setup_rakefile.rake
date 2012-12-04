
require 'protk/constants.rb'
require 'rbconfig'

env=Constants.new

@build_dir = "#{env.protk_dir}/tmp/build"
@download_dir = "#{env.protk_dir}/tmp/download"

directory @build_dir
directory @download_dir

def package_manager_name 
	package_managers = ["brew","yum","apt-get"]

	package_managers.each do |pmname|  
		if supports_package_manager pmname
			return pmname
		end
	end
end

def supports_package_manager name
	res = %x[which #{name}]
	(res == "")
end

def clean_build_dir
	sh %{cd #{@build_dir}; rm -rf ./*}
end

def download_buildfile url, file
	sh %{cd #{@download_dir}; wget  #{url}}
end

def download_task url, packagefile
	file "#{@download_dir}/#{packagefile}" => @download_dir do 
		download_buildfile "#{url}", "#{packagefile}"
	end
end

#
# Package manager
#
task :package_manager do
	pmname = package_manager_name
	needs_homebrew=false
	sh "which #{pmname}" do |ok,res|
		unless ok
			throw "Missing package manager #{pmname}" unless  pmname=='brew'
			needs_homebrew=true
		end
	end

	if needs_homebrew
		sh { "ruby -e \"$(curl -fsSkL raw.github.com/mxcl/homebrew/go)" }
		sh { "brew update"}
		sh { "brew tap homebrew/versions"}
	end

end

#
# System packages
#
task :system_packages => :package_manager do
	# Gather package requirements 
	pkgs=YAML::load(File.open("#{File.dirname(__FILE__)}/data/#{package_manager_name}_packages.yaml"))

	unique_packages=[]
	apps=[]
	installed_packages=[]
	for pk in pkgs 
    	unique_packages = pk[1] | unique_packages
    	apps = apps.push pk[0]
  	end

  	# Install all packages
  	#
  	unique_packages.each { |pk|  
  		sh "#{package_manager_name} install #{pk}" do |ok,res|
  			p res
  			installed_packages.push pk if ok
  		end
  	}

end

#
# Perl local::lib
#
perl_locallib_version="1.008004"
perl_locallib_packagefile="local-lib-#{perl_locallib_version}.tar.gz"
perl_locallib_installed_file = "#{env.protk_dir}/perl5/lib/perl5/local/lib.pm"
perl_locallib_url = "http://search.cpan.org/CPAN/authors/id/A/AP/APEIRON/local-lib-#{perl_locallib_version}.tar.gz"

download_task perl_locallib_url, perl_locallib_packagefile

file perl_locallib_installed_file =>  [@build_dir,"#{@download_dir}/#{perl_locallib_packagefile}"] do
	sh %{cp #{@download_dir}/#{perl_locallib_packagefile} #{@build_dir}}
	perl_dir = "#{env.protk_dir}/perl5"

	sh %{cd #{@build_dir}; gunzip local-lib-#{perl_locallib_version}.tar.gz } 
	sh %{cd #{@build_dir}; tar -xf local-lib-#{perl_locallib_version}.tar } 
	sh "cd #{@build_dir}/local-lib-#{perl_locallib_version}; perl Makefile.PL --bootstrap=#{perl_dir}; make install" do |ok,res|
#		clean_build_dir if ok
	end

	if !Pathname.new("~/.bashrc").exist? || File.read("~/.bashrc") =~ /Mlocal::lib/
		sh "echo 'eval $(perl -I#{perl_dir}/lib/perl5 -Mlocal::lib=#{perl_dir})' >>~/.bashrc"
	end

	if !Pathname.new("~/.bash_profile").exist? || File.read("~/.bash_profile") =~ /Mlocal::lib/
		sh "echo 'eval $(perl -I#{perl_dir}/lib/perl5 -Mlocal::lib=#{perl_dir})' >>~/.bash_profile"
	end
end

task :perl_locallib => [perl_locallib_installed_file]


#
# Top Level Packages. 
#


#
# TPP
#
tpp_version="4.6.1"
tpp_packagefile="TPP-#{tpp_version}.tgz"
tpp_installed_file = "#{env.xinteract}"
tpp_url = "https://dl.dropbox.com/u/226794/TPP-4.6.1.tgz"

download_task tpp_url, tpp_packagefile

# Build
file tpp_installed_file => [:perl_locallib,@build_dir,"#{@download_dir}/#{tpp_packagefile}"] do
	sh %{cp #{@download_dir}/#{tpp_packagefile} #{@build_dir}}
	sh %{cpanm --local-lib=#{env.protk_dir}/perl5 XML::Parser}
	sh %{cpanm --local-lib=#{env.protk_dir}/perl5 XML::CGI --force}

	sh %{cd #{@build_dir};tar -xvzf TPP-#{tpp_version}.tgz}

	File.open("#{@build_dir}/TPP-#{tpp_version}/trans_proteomic_pipeline/src/Makefile.config.incl","wb") do |f|
		f.write "TPP_ROOT=#{env.tpp_root}/\nTPP_WEB=/tpp/\nXSLT_PROC=/usr/bin/xsltproc\nCGI_USERS_DIR=${TPP_ROOT}cgi-bin/"
	end

	makefile_incl_path="#{@build_dir}/TPP-#{tpp_version}/trans_proteomic_pipeline/src/Makefile.incl"
	makefile_incl_text=File.read("#{makefile_incl_path}")

	# Homebrew specific modifications to makefiles
	#
	if ( package_manager_name=='brew')
		File.open("#{makefile_incl_path}","w+") do |f|
			subs_text = makefile_incl_text.gsub(/GD_LIB= \/opt\/local\/lib\/libgd.a \/opt\/local\/lib\/libpng.a/,"GD_LIB= /usr/local/lib/libgd.a /usr/local/opt/libpng12/lib/libpng.a") #We're using homebrew not fink or macports
			subs_text = subs_text.gsub(/GD_INCL= -I \/opt\/local\/include\//,"GD_INCL= -I /usr/local/include/ -I /usr/local/opt/libpng12/include")
			f.write subs_text
		end	

		makefile_path="#{@build_dir}/TPP-#{tpp_version}/trans_proteomic_pipeline/CGI/Makefile"
		makefile_text = File.read("#{makefile_path}")

		File.open("#{makefile_path}","w+") do |f|
			subs_text = makefile_text.gsub("cp -rfu","cp -rf")
			f.write subs_text
		end
	end
	sh %{cd #{@build_dir}/TPP-#{tpp_version}/trans_proteomic_pipeline/src ; make; make install}

end

task :tpp => tpp_installed_file



#
# omssa
#
def omssa_platform 
	if RbConfig::CONFIG['host_os'] =~ /darwin/ 
		return 'macos'
	end
	'linux'
end

omssa_packagefile="omssa-#{omssa_platform}.tar.gz"
omssa_installed_file = "#{env.omssacl}"
omssa_url = "ftp://ftp.ncbi.nih.gov/pub/lewisg/omssa/CURRENT/omssa-#{omssa_platform}.tar.gz"

download_task omssa_url, omssa_packagefile

# Install
file omssa_installed_file => [@build_dir,"#{@download_dir}/omssa-#{omssa_platform}.tar.gz"] do
	sh %{cp #{@download_dir}/#{omssa_packagefile} #{@build_dir}}
    sh %{cd #{@build_dir}; gunzip omssa-#{omssa_platform}.tar.gz}
    sh %{cd #{@build_dir}; tar -xvf omssa-#{omssa_platform}.tar}
    sh %{mkdir -p #{env.omssa_root}}
    sh %{cd #{@build_dir}; cp -r omssa-*.#{omssa_platform}/* #{env.omssa_root}/}
end

task :omssa => omssa_installed_file



#
# blast
#
def blast_platform 
	if RbConfig::CONFIG['host_os'] =~ /darwin/ 
		return 'universal-macosx'
	end
	'x64-linux'
end

blast_version="2.2.27+"
blast_packagefile="ncbi-blast-#{blast_version}-#{blast_platform}.tar.gz"
blast_url="ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/#{blast_version.chomp('+')}/#{blast_packagefile}"
blast_installed_file="#{env.makeblastdb}"

download_task blast_url, blast_packagefile

# Install
file blast_installed_file => [@build_dir,"#{@download_dir}/#{blast_packagefile}"] do
	sh %{cp #{@download_dir}/#{blast_packagefile} #{@build_dir}}
    sh %{cd #{@build_dir}; gunzip #{blast_packagefile}}
    sh %{cd #{@build_dir}; tar -xvf #{blast_packagefile.chomp('.gz')}}
    sh %{mkdir -p #{env.blast_root}}
    sh %{cd #{@build_dir}; cp -r ncbi-blast-#{blast_version}/* #{env.blast_root}/}
end

task :blast => blast_installed_file


#
# MSGFPlus
#
msgfplus_version="20121116"
msgfplus_packagefile="MSGFPlus.#{msgfplus_version}.zip"
msgfplus_url="http://proteomics.ucsd.edu/Downloads/MSGFPlus.#{msgfplus_version}.zip"
msgfplus_installed_file="#{env.msgfplusjar}"

download_task msgfplus_url, msgfplus_packagefile

file msgfplus_installed_file => [@build_dir,"#{@download_dir}/#{msgfplus_packagefile}"] do
	sh %{cp #{@download_dir}/#{msgfplus_packagefile} #{@build_dir}}
    sh %{cd #{@build_dir}; unzip #{msgfplus_packagefile}}
    sh %{mkdir -p #{env.msgfplus_root}}
    sh %{cd #{@build_dir}; cp MSGFPlus.jar #{env.msgfplus_root}/}
end

task :msgfplus => msgfplus_installed_file

#
# pwiz
#
def pwiz_platform 
	if RbConfig::CONFIG['host_os'] =~ /darwin/ 
		return 'darwin-x86-xgcc40'
	end
	'linux-x86_64-gcc42'
end

def platform_bunzip
	if RbConfig::CONFIG['host_os'] =~ /darwin/ 
		return 'pbunzip2'
	end
	'bunzip2'
end

pwiz_version="3_0_4146"
pwiz_packagefile="pwiz-bin-#{pwiz_platform}-release-#{pwiz_version}.tar.bz2"
pwiz_url="https://dl.dropbox.com/u/226794/#{pwiz_packagefile}"
pwiz_installed_file="#{env.idconvert}"

download_task pwiz_url, pwiz_packagefile

file pwiz_installed_file => [@build_dir,"#{@download_dir}/#{pwiz_packagefile}"] do 
	sh %{cp #{@download_dir}/#{pwiz_packagefile} #{@build_dir}}
    sh %{cd #{@build_dir}; #{platform_bunzip} -f #{pwiz_packagefile}}
    sh %{cd #{@build_dir}; tar -xvf #{pwiz_packagefile.chomp('.bz2')}}
    sh %{mkdir -p #{env.pwiz_root}}
    sh %{cd #{@build_dir}; cp idconvert msconvert #{env.pwiz_root}/}
end

task :pwiz => pwiz_installed_file

task :all => [:tpp,:omssa,:blast,:msgfplus,:pwiz]

