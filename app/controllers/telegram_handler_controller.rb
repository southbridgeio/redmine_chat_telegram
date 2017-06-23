class TelegramHandlerController < ActionController::Metal
  def handle
    TelegramHandlerWorker.perform_async(params)

    self.status = 200
    self.response_body = ''
  end
end
