# http://docs.knapsackpro.com/2017/circleci-2-0-capybara-feature-specs-selenium-webdriver-with-chrome-headless
JS_DRIVER = :selenium_chrome_headless

Capybara.default_driver = :rack_test
Capybara.javascript_driver = JS_DRIVER
Capybara.default_max_wait_time = 2

RSpec.configure do |config|
  config.before(:each) do |example|
    Capybara.current_driver = JS_DRIVER if example.metadata[:js]
    Capybara.current_driver = :selenium if example.metadata[:selenium]
    Capybara.current_driver = :selenium_chrome if example.metadata[:selenium_chrome]
  end

  config.after(:each) do
    Capybara.use_default_driver
  end
end