prawn_document(
    :filename=>"#{@project.name}.pdf",
    :inline => true,
    :page_layout=>:landscape,
    :margin => 0) do |pdf|

  @num_cards_on_page = 0

  pdf.font "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"

  @project.latest_iteration.stories.each_with_index do |card, i|

    # --- Split pages
    if i > 0 and i % 4 == 0
      pdf.start_new_page
      @num_cards_on_page = 1
    else
      @num_cards_on_page += 1
    end

    # --- Define 2x2 grid
    pdf.define_grid(:columns => 2, :rows => 2, :gutter => 42)
    # pdf.grid.show_all

    row = (@num_cards_on_page+1) / 4
    column = i % 2

    # p @num_cards_on_page
    # p [ row, column ]

    padding = 12

    cell = pdf.grid(row, column)
    cell.bounding_box do

      pdf.stroke_color = "666666"
      pdf.stroke_bounds

      # --- Write content
      pdf.text_box card.name, :size => 14, :at => [pdf.bounds.left+padding, pdf.bounds.top-padding], :width => cell.width-18, :height => 40
      #      pdf.horizontal_line pdf.bounds.left+padding, pdf.bounds.left+padding + cell.width-21, :at => pdf.bounds.top-padding-31
      pdf.text_box card.body, :size => 9, :at => [pdf.bounds.left+padding, pdf.bounds.top-padding-35], :width => cell.width-18, :height => cell.height-80
      pdf.fill_color "000000"

      pdf.text_box "Points: #{card.points}",
                   :size => 12, :at => [12, 33], :width => cell.width-18
      pdf.text_box "Owner: #{card.owner}",
                   :size => 8, :at => [12, 18], :width => cell.width-18

      pdf.fill_color "999999"
      pdf.text_box card.story_type.capitalize, :size => 8, :align => :right, :at => [12, 18], :width => cell.width-18
      pdf.fill_color "000000"

    end

  end

  # --- Footer
  #    pdf.number_pages "#{@project.name}.pdf", [pdf.bounds.left,  -28]
  #    pdf.number_pages "<page>/<total>", [pdf.bounds.right-16, -28]
end
