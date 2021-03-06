module Catalog
  class CreateApprovalRequest
    attr_reader :order

    def initialize(task, tag_resources, order_item = nil)
      @task = task
      order_item ||= OrderItem.find_by!(:topology_task_ref => task.id)
      @order = order_item.order
      @tag_resources = tag_resources
    end

    def process
      @order.mark_approval_pending

      # Possibly in the future we may want to create approval requests for
      # a before or after order item, but currently it is only for the
      # applicable product.
      @order.order_items.where(:process_scope => 'product').each do |order_item|
        submit_approval_requests(order_item)
      end

      self
    end

    private

    def submit_approval_requests(order_item)
      response = Approval::Service.call(ApprovalApiClient::RequestApi) do |api|
        api.create_request(Catalog::CreateRequestBodyFrom.new(@order, order_item, @task, @tag_resources).process.result)
      end

      order_item.approval_requests.create!(
        :approval_request_ref => response.id,
        :state                => response.decision.to_sym,
        :tenant_id            => order_item.tenant_id
      )

      Rails.logger.info("Approval Requests Submitted for Order #{@order.id}")
    rescue Catalog::ApprovalError => e
      order_item.mark_failed("Error while creating approval request: #{e.message}")
    end
  end
end
