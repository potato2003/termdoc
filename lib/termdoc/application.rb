# -*- encoding: utf-8 -*-"

# require 'termdoc/application'

require 'csv'
require 'ostruct'
require 'singleton'

# thrid-party library
require 'colorize'

module Termdoc

  class Application

    # given config is hash object created from command line arguments.
    #
    def initialize(config)
      @sources      = config[:src]
      @term_file    = config[:term]
      @output_level = (config[:silence] && :silence) ||
                      (config[:verb] && :verbose)
      @terms = {}

      # get list of source codes paths.
      #@sources.each do |s|
      #  if 
      #  File::exist? s
      #end

      #
      # safety chack
      #
      #unless File::exist? @sources # allows directory or file
      #  warn "[ERROR] specfied source path is invalid, check the path and try again.".colorize(:red)
      #  exit false
      #end

      unless File::file?(@term_file)
        warn "[ERROR] specfied term file is not found, check the path and try again.".colorize(:red)
        exit false
      end
    end

    def run
      load_term_file(@term_file)
      execute
    end

  private
    def load_term_file(term_file)
      @terms = {}
      CSV.foreach(term_file) do |r|
        next if r.empty?
        fail "faild to parse row in term file, filed size is 2 only." if r.size == 1
        r[1] = r[1..-1].join(',') if 2 < r.size

        term = r[0].strip
        description= r[1].strip

        @terms[term] = description
      end
    end

    def execute()
      @sources.each do |src|
        case File::extname(src)
          when ".scala"
            raw_src = File.read(src)

            # extract a doc comment block from source code.
            doc_comment_blocks = raw_src.scan(/\/\*\*.+\*\//m)

            # insert a terms descriptions after '@term' in comment blocks.
            doc_comment_blocks.each do |b|
              b.gsub!(/(?<front_side>\*\s+@term\s+(?<termdoc>[a-zA-Z0-9.]+)).*/) do |term_word|
                # matches exsample:
                # 
                # * @term {term-word} {descriptions ...}
                #         ^^^^^^^^^^^ assign matched result to `termdoc`
                # ^^^^^^^^^^^^^^^^^^^^ assign matched result to `front_side`

                # fail "found a unknown termdoc error. '#{$~[:termdoc]}'" if @terms.has_key?($~[:termdoc])

                "#{$~[:front_side]} #{@terms[$~[:termdoc]]}"
              end

              # replace src file.
              File.write(src, b)
            end
        end
      end
    end

    # True if enabled verbose mode, false otherwise
    def verbose_mode?
      @output_level == :verbose
    end

    # True if enabled silence mode, false otherwise
    def silence_mode?
      @output_level == :silence
    end

  end
end
