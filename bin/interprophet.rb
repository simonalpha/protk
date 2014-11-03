#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Runs the InterProphet tool on a set of pep.xml files generated by peptide_prophet
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/prophet_tool'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
prophet_tool=ProphetTool.new([
  :explicit_output,
  :over_write,
  :probability_threshold,
  :threads,
  :prefix])

prophet_tool.option_parser.banner = "Run InterProphet on a set of pep.xml input files.\n\nUsage: interprophet.rb [options] file1.pep.xml file2.pep.xml ..."
@output_suffix="_iproph"


prophet_tool.add_boolean_option(:no_nss,false,['--no-nss', 'Don\'t use NSS (Number of Sibling Searches) in Model'])
prophet_tool.add_boolean_option(:no_nrs,false,['--no-nrs', 'Don\'t use NRS (Number of Replicate Spectra) in Model'])
prophet_tool.add_boolean_option(:no_nse,false,['--no-nse', 'Don\'t use NSE (Number of Sibling Experiments) in Model'])
prophet_tool.add_boolean_option(:no_nsi,false,["--no-nsi",'Don\'t use NSE (Number of Sibling Ions) in Model'])
prophet_tool.add_boolean_option(:no_nsm,false,["--no-nsm",'Don\'t use NSE (Number of Sibling Modifications) in Model'])
# prophet_tool.add_value_option(:min_prob,"",["--minprob mp","Minimum probability cutoff "])

exit unless prophet_tool.check_options(true)


# Obtain a global environment object
genv=Constants.new

inputs = ARGV.collect {|file_name| 
  file_name.chomp
}

if ( prophet_tool.explicit_output != nil )
  output_file=prophet_tool.explicit_output
else
  output_file=Tool.default_output_path(inputs[0],".pep.xml",prophet_tool.output_prefix,@output_suffix)
end

if ( !Pathname.new(output_file).exist? || prophet_tool.over_write )

  cmd="InterProphetParser "
  cmd<<"THREADS=#{prophet_tool.threads.to_i}" if prophet_tool.threads.to_i > 0
  cmd<<"NONSS " if prophet_tool.options.no_nss
  cmd<<"NONRS " if prophet_tool.options.no_nrs
  cmd<<"NONSE " if prophet_tool.options.no_nse
  cmd<<"NONSI " if prophet_tool.options.no_nsi
  cmd<<"NONSM " if prophet_tool.options.no_nsm


  cmd << " MINPROB=#{prophet_tool.probability_threshold}" if ( prophet_tool.probability_threshold !="" )

  if for_galaxy
    inputs = inputs.collect {|ip| GalaxyUtil.stage_pepxml(ip) }
  end

  input_files = inputs.collect { |e| e.staged_path }

  cmd << " #{input_files.join(" ")} #{output_file}"

  genv.log("Running #{cmd}",:info)

  # Run the analysis
  #
  code = prophet_tool.run(cmd,genv)
  throw "Command failed with exit code #{code}" unless code==0

  if for_galaxy
    inputs.each do |ip_stager|
      ip_stager.restore_references(output_file)
    end
  end
    
else
  genv.log("Interprophet output file #{output_file} already exists. Run with -r option to replace",:warn)   
end






