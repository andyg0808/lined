#  Copyright 2014 Andrew Gilbert

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

require 'tempfile'
require 'tmpdir'
require 'spec_helper'

LINE = "This string should be written to the file"
LINE2 = "It has two lines."

LINES = LINE + "\n" + LINE2

def getLined string
  if string.is_a? Array
    string = string.join Lined::Lined::SEPARATOR
  end

  io = StringIO.new string
  Lined::Lined.new io
end

module Lined
  describe Lined do
    describe "#initialize" do
      it "can use a path" do
        Tempfile.create('lined') do |f|
          # Given a file with a line in it...
          f << LINE
          f.rewind
          f.fsync

          lined = Lined.new f.path

          expect(lined.first).to eq(LINE)
        end
      end

      it "can use a non-existing path" do
        Dir.mktmpdir do |dir|
          Lined.new File.join(dir, 'filename')
        end
      end

      it "can use an IO object" do
        io = StringIO.new LINE
        lined = Lined.new io
        expect(lined.first).to eq(LINE)
      end
    end

    describe "#get" do
      before :each do
        @lined = getLined LINES
      end

      it "matches against regex" do
        expect(@lined.get(/This/)).to eq([LINE])
      end

      it "accepts 1-based line numbers" do
        expect(@lined.get(1)).to eq([LINE])
      end

      it "returns all matching lines" do
        lined = getLined LINES + "\n" + LINES

        expect(lined.get(/This/)).to eq([LINE, LINE])
      end

      it "throws an error if a line number is out of range" do
        expect { @lined.get(3) }.to raise_error(IndexError)
      end
    end

    describe "#only" do
      before :each do
        @lined = getLined LINES
      end
      context "with an arguement" do
        it "matches against regex" do
          expect(@lined.only(/This/)).to eq(LINE)
        end

        it "accepts line numbers" do
          expect(@lined.only(1)).to eq(LINE)
        end

        it "returns a found line" do
          expect(@lined.only(1)).to eq(LINE)
        end

        it "fails if there is more than one match" do
          lined = getLined LINES + "\n" + LINES

          expect { lined.only(/This/) }.to raise_error(RuntimeError)
        end
      end

      context "without arguments" do
        it "returns the only line in the file" do
          lined = getLined LINE

          expect(lined.only).to eq(LINE)
        end
        it "fails if there are no arguments and the file has more than one line" do
          expect { @lined.only }.to raise_error(RuntimeError)
        end
      end
    end

    describe "#first" do
      it "returns the first line in the document" do
        lined = getLined LINE

        expect(lined.first).to eq(LINE)
      end
    end

    describe "#<<" do
      it "aliases #push" do
        expect(Lined.instance_method(:<<)).to eq(Lined.instance_method(:push))
      end
    end

    describe "#push" do
      it "appends a line to the end of the file" do
        lined = getLined LINE
        lined.push "test"
        expect(lined.only(-1)).to eq("test")
      end
    end

    describe "#unshift" do
      it "appends a line to the beginning of the file" do
        lined = getLined LINE
        lined.unshift "test"
        expect(lined.only(1)).to eq("test")
      end
    end

    describe "#save" do
      it "writes the changes to the file" do
        string = String.new LINES
        lined = getLined string
        lined.only(-1) << LINE

        lined.save

        expect(string).to eq(LINES + LINE)
      end

      it "preserves original trailing newlines" do
        string = LINES + ?\n
        lined = getLined string

        lined.save

        expect(string).to eq(LINES + ?\n)
      end
    end

    describe "#line_index" do
      let(:lined) { getLined LINES }

      it "returns the number of the matching line" do
        expect(lined.line_indices(/This/)).to eq([1])
      end

      it "matches against a regex" do
        expect(lined.line_indices(/This/)).to eq([1])
      end

      it "accepts one-based line numbers" do
        expect(lined.line_indices(1)).to eq([1])
      end

      it "accepts an array of descriptors" do
        expect(lined.line_indices([1, 2])).to eq([1, 2])
        expect(lined.line_indices([/This/, /It/])).to eq([1, 2])
      end

      it "throws an exception if the index is invalid" do
        expect { lined.line_indices(3) }.to raise_error(IndexError)
      end
    end

    describe "#replace" do
      context "with two arguments" do
        let(:lined) { getLined LINES }

        it "replaces a line" do
          lined.replace(1, LINE2)

          expect(lined.only(1)).to eq(LINE2)
        end

        it "matches against a regex" do
          lined.replace(/This/, LINE2)

          expect(lined.only(1)).to eq(LINE2)
        end

        it "accepts one-based line numbers" do
          lined.replace(2, LINE)

          expect(lined.only(2)).to eq(LINE)
        end

        it "throws an exception if more than one line matches" do
          lined = getLined [LINE, LINE]

          expect { lined.replace(/This/, LINE2) }.to raise_error(RuntimeError)
        end

        it "accepts multiple lines to add as a string" do
          #pending "getting unary array working"
          lined.replace(/This/, LINES)

          expect(lined.only 1).to eq(LINE)
          expect(lined.only 2).to eq(LINE2)
          expect(lined.only 3).to eq(LINE2)
        end

        it "accepts multiple lines to add as an array" do
          lined.replace(/This/, [LINE2, LINE2])

          expect(lined.only 1).to eq(LINE2)
          expect(lined.only 2).to eq(LINE2)
          expect(lined.only 3).to eq(LINE2)
        end
      end

      context "with one argument" do
        it "replaces the only line in the file" do
          lined = getLined LINE

          lined.replace(LINE2)

          expect(lined.only).to eq(LINE2)
        end

        it "throws an exception if more than one line is in the file" do
          lined = getLined LINES

          expect { lined.replace(LINE2) }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
