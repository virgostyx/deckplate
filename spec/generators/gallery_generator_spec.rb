require "spec_helper"
require "generators/deckplate/gallery/gallery_generator"

RSpec.describe Deckplate::Generators::GalleryGenerator do
  let(:root) { FixtureApp.build }
  let(:routes) { "Rails.application.routes.draw do\n  root \"home#index\"\nend\n" }
  after { FileUtils.remove_entry(root) if root && File.exist?(root) }

  before { FixtureApp.write(root, "config/routes.rb", routes) }

  def run_gallery(destination = root)
    out = StringIO.new
    original = [ $stdout, $stderr ]
    $stdout = $stderr = out
    described_class.start([], destination_root: destination)
    out.string
  ensure
    $stdout, $stderr = original
  end

  it "adds a controller, a view and a development-only route" do
    run_gallery
    expect(FixtureApp.read(root, "app/controllers/deckplate_gallery_controller.rb")).to include("class DeckplateGalleryController < ApplicationController")
    expect(FixtureApp.exist?(root, "app/views/deckplate_gallery/show.html.erb")).to be(true)
    expect(FixtureApp.read(root, "config/routes.rb")).to include('get "deckplate", to: "deckplate_gallery#show" if Rails.env.development?')
  end

  it "refuses to serve outside development, even if the route is copied elsewhere" do
    run_gallery
    controller = FixtureApp.read(root, "app/controllers/deckplate_gallery_controller.rb")
    expect(controller).to include("Rails.env.development?").and include("RoutingError")
  end

  it "keeps the existing routes" do
    run_gallery
    expect(FixtureApp.read(root, "config/routes.rb")).to include('root "home#index"')
  end

  it "is idempotent" do
    run_gallery
    first = FixtureApp.snapshot(root)
    expect(run_gallery).to match(/already|exist|identical/i)
    expect(FixtureApp.snapshot(root)).to eq(first)
  end

  it "prints the route to add when it cannot find the routes file" do
    FileUtils.rm_f(File.join(root, "config/routes.rb"))
    expect(run_gallery).to include('get "deckplate"')
  end

  it "keeps a view the host already edited" do
    FixtureApp.write(root, "app/views/deckplate_gallery/show.html.erb", "<p>mine</p>\n")
    run_gallery
    expect(FixtureApp.read(root, "app/views/deckplate_gallery/show.html.erb")).to eq("<p>mine</p>\n")
  end

  describe "the generated view" do
    it "renders with the real components (no API drift)" do
      html = ApplicationController.render(inline: File.read(described_class.source_root + "/show.html.erb"), type: :erb)
      expect(html).to include("dp-frame").and include("Colour roles").and include("Emergency").and include("dp-table")
    end
  end
end
