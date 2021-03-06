require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The make_decoy tool" do

	describe ["make_decoy.rb"] do
		it_behaves_like "a protk tool"
	end

	describe "Running with sample data" do

		include_context :tmp_dir_with_fixtures, ["testdb.fasta"]

		before(:each) do
			@input_file="#{@tmp_dir}/testdb.fasta"
			@output_file="#{@tmp_dir}/output.fasta"
			@num_entries_in_test=4
		end

		it "-o option works" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file}]
			expect(@output_file).to exist?
			expect(@output_file).to be_fasta
		end

		it "-L option produces the correct number of entries" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file} -L 5]
			expect(@output_file).to be_fasta
			expect(@output_file).to have_fasta_entries(5)
		end

		it "-L option ignored with --reverse-only" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file} -L #{@num_entries_in_test+2} --reverse-only]
			expect(@output_file).to be_fasta
			expect(@output_file).to have_fasta_entries(@num_entries_in_test)
		end

		it "-P option produces entries with correct prefix" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file} -P "testprefix_"]
			expect(@output_file).to be_fasta
			expect(@output_file).to have_fasta_entries_matching(@num_entries_in_test,"^testprefix_")
		end


		it "-P option works with --reverse-only" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file} -P "testprefix_" --reverse-only]
			expect(@output_file).to be_fasta
			expect(@output_file).to have_fasta_entries_matching(@num_entries_in_test,"testprefix_")
		end

		it "-A option appends entries" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file} -P "testprefix_" -A]
			expect(@output_file).to be_fasta
			expect(@output_file).to have_fasta_entries(@num_entries_in_test*2)
			expect(@output_file).to have_fasta_entries_matching(@num_entries_in_test,"^testprefix_")
		end

		it "-A option works with --reverse-only" do
			%x[make_decoy.rb #{@input_file} -o #{@output_file} -P "testprefix_" -A --reverse-only]
			expect(@output_file).to be_fasta
			expect(@output_file).to have_fasta_entries(@num_entries_in_test*2)
			expect(@output_file).to have_fasta_entries_matching(@num_entries_in_test,"testprefix_")
		end

	end
end