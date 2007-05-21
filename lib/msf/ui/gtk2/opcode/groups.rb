module Msf
  module Ui
    module Gtk2

      #
      # Gtk2 Interface for Metasploit Opcodes database
      #
      class MsfOpcode

        # Create the opcode client instance
        $client = Rex::Exploitation::OpcodeDb::Client.new

        #
        # Opcodes groups
        #
        class Groups < Msf::Ui::Gtk2::SkeletonOpcode
          def initialize
            comment = "Opcode groups currently supported by the database :"

            # call the parent
            super("Groups", comment)

            textview = Gtk::TextView.new
            textbuffer = Gtk::TextBuffer.new
            stuff.pack_start(textview, true, true, 0)

            gs = "\n"
            $client.groups.each do |g|
              gs << " - " + g.name + "\n"
            end

            textbuffer.set_text( gs )

            textview.set_buffer(textbuffer)
            textview.set_editable(false)
            textview.set_cursor_visible(false)

            show_all and run
            destroy
          end
        end

      end

    end
  end
end
