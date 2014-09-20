require 'forwardable'
module Lined
  class Lined
     extend Forwardable

     SEPARATOR = ?\n

     def initialize io
       if io.is_a? String
         @io = File.new io, File::RDWR | File::CREAT
         @io.rewind
       else
         @io = io
       end

       # Make sure we break lines on newlines, so we can put them back together
       @lines = @io.readlines(SEPARATOR)
       last_line = @lines.last

       @trailing_newline = last_line && last_line[-1] == ?\n

       @lines = @lines.map { |l| l.strip }
     end

     def_delegator :@lines, :push, :push
     def_delegator :@lines, :unshift, :unshift
     alias << push

     def index descriptor
       if descriptor.is_a? Array
         descriptor.flat_map { |d| index d }
       elsif descriptor.is_a? Regexp
         matches = Array.new
         @lines.each_index do |i|
           if descriptor =~ @lines[i]
             matches << i
           end
         end
         matches
       elsif descriptor.is_a? Integer
         if descriptor > 0 and descriptor <= @lines.length
           [(descriptor - 1)]
         elsif descriptor < 0 and descriptor >= -@lines.length
           [descriptor]
         else
           raise IndexError.new "Invalid line number: #{descriptor}"
         end
       else
         raise ArgumentError.new "Invalid descriptor; descriptor class is #{descriptor.class}"
       end
     end

     private :index

     def get_only array
       if array.length > 1
         raise "Too many matching lines"
       elsif array.length < 1
         raise "Too few matching lines"
       end

       array.first
     end

     def line_indices descriptor
       index(descriptor).map { |i| i + 1 }
     end

     def get descriptor
       indices = index descriptor
       @lines.values_at *indices
     end

     def only descriptor=nil
       if descriptor
         matches = get(descriptor)
       else
         matches = @lines
       end

       get_only matches
     end

     def first
       if @lines and @lines[0]
         @lines[0]
       else
         nil
       end
     end

     def replace replacement_or_descriptor, replacement = nil
       if replacement
         descriptor = replacement_or_descriptor

         indices = index descriptor
         i = get_only indices
       else
         replacement = replacement_or_descriptor
         get_only @lines
         i = 0
       end

       if replacement =~ /#{SEPARATOR}/
         replacement = replacement.split SEPARATOR
       elsif not replacement.is_a? Array
         replacement = [replacement]
       end

       @lines[i, 1] = replacement
     end

     def save
       @io.rewind
       @io.truncate 0
       @io.write @lines.join(SEPARATOR)
       if @trailing_newline
         @io.write ?\n
       end
     end
  end
end
