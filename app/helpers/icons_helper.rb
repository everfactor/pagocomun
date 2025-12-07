module IconsHelper
  def icon(name, classes: "size-6 shrink-0")
    render "shared/icons/#{name}", classes: classes
  end
end
