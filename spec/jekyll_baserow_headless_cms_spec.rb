# frozen_string_literal: true

RSpec.describe JekyllBaserowHeadlessCMS do
  it 'has a version number' do
    expect(JekyllBaserowHeadlessCMS::VERSION).not_to be_nil
    expect(JekyllBaserowHeadlessCMS::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  it 'defines error classes' do
    expect(JekyllBaserowHeadlessCMS::Error).to be < StandardError
    expect(JekyllBaserowHeadlessCMS::ConfigurationError).to be < JekyllBaserowHeadlessCMS::Error
    expect(JekyllBaserowHeadlessCMS::APIError).to be < JekyllBaserowHeadlessCMS::Error
  end
end
