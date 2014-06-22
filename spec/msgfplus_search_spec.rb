require 'spec_helper'
require 'commandline_shared_examples.rb'

def msgfplus_not_installed
	installed=(%x[which MSGFPlus.jar].length>0)
	!installed
end

describe "The xmsgfplus_search command", :broken => false do

	include_context :tmp_dir_with_fixtures, ["tiny.mzML","testdb.fasta"]

	before(:each) do
		@input_file="#{@tmp_dir}/tiny.mzML"
	    @db_file = "#{@tmp_dir}/testdb.fasta"
    	@output_file="#{@tmp_dir}/tiny_msgfplus.pepXML"
		@extra_args="-d #{@db_file}"    	
	end


	describe ["msgfplus_search.rb",".mzid","_msgfplus"] do
		it_behaves_like "a protk tool"
		it_behaves_like "a protk tool with default file output"		
	end

	it "should run a search using absolute pathnames", :dependencies_not_installed => msgfplus_not_installed do

		%x[msgfplus_search.rb -d #{@db_file} #{@input_file} -o #{@output_file}]
		
		expect(@output_file).to exist?
		expect(@output_file).to be_mzidentml		
	end


	# it "should run a search using relative pathnames",:broken=>true, :dependencies_not_installed => msgfplus_not_installed do

	# 	Dir.chdir(@tmp_dir)
	# 	input_file="tiny.mzML"
	# 	db_file = "testdb.fasta"

	# 	output_file="tiny_msgfplus.msgfplus"
	# 	expect(output_file).not_to exist?

	# 	%x[msgfplus_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
	# 	expect(output_file).to exist?	
	# end

	it "should support the --pepxml option", :dependencies_not_installed => msgfplus_not_installed do

		%x[msgfplus_search.rb -d #{@db_file} #{@input_file} -o #{@output_file} --pepxml]
		
		expect(@output_file).to exist?
		expect(@output_file).to be_pepxml		
		expect(@output_file).to have_pepxml_hits_matching(2,/BOVIN/)
	end


end

