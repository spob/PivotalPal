module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def bold_text(text, bold)
    return text unless bold
    "<strong>".html_safe + text + "</strong>".html_safe
  end

  def strike_text(text, strike)
    return text unless strike
    "<strike>".html_safe + text + "</strike>".html_safe
  end
end
