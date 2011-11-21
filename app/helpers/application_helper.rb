module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def bold_text(text, bold)
    return h(text) unless bold
    "<strong>".html_safe + h(text) + "</strong>".html_safe
  end

  def strike_text(text, strike)
    return h(text) unless strike
    "<span class='strike'>".html_safe + h(text) + "</span>".html_safe
  end

  def show_link(object, prefix=nil, content=t('action.show'))
    ((prefix ? prefix : "") + link_to(content, object)).html_safe
  end

  def edit_link(object, prefix=nil, content=t('action.edit'))
    ((prefix ? prefix : "") + link_to(content, [:edit, object])).html_safe if can?(:update, object)
  end

  def destroy_link(object, prefix=nil, content = t('action.destroy'))
    ((prefix ? prefix : "") + link_to(content, object, :method => :delete, :confirm => "Are you sure?")).html_safe if can?(:destroy, object)
  end

  def create_link(object, prefix=nil, content = t('action.new'))
    if can?(:create, object)
      object_class = (object.kind_of?(Class) ? object : object.class)
      ((prefix ? prefix : "") + link_to(content, [:new, object_class.name.underscore.to_sym])).html_safe
    end
  end
end
