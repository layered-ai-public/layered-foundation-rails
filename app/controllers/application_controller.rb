class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # WCAG 2.4.2 (Page Titled): every page must have a descriptive <title>. This sets
  # a sensible default (the application name) so no page ever ships title-less;
  # override per action with @page_title, and set @page_description for the
  # <meta name="description"> tag. Both are rendered by the layered-ui layout.
  before_action :set_default_page_title

  private

  def set_default_page_title
    @page_title = Rails.application.class.module_parent_name.titleize
  end
end
