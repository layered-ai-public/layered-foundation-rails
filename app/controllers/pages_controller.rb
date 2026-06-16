class PagesController < ApplicationController
  def index
    # @page_title falls back to the application name (set in ApplicationController),
    # which is the right title for the landing page. Override @page_title on other
    # pages, and set @page_description for the <meta name="description"> tag.
    @page_description = "Welcome to your new Rails app, built on layered-ui-rails."
  end
end
