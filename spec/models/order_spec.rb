describe Order do
  let!(:order1) { create(:order) }
  let!(:order2) { create(:order) }
  let!(:order3) { create(:order, :owner => 'barney') }

  context "scoped by owner" do
    it "#by_owner" do
      Insights::API::Common::Request.with_request(default_request) do
        expect(Order.by_owner.collect(&:id)).to match_array([order1.id, order2.id])
        expect(Order.all.count).to eq(3)
      end
    end
  end

  describe "#discard before hook" do
    context "when the order has order items" do
      let!(:order_item) { create(:order_item, :order_id => order1.id) }

      it "destroys order_items associated with the order" do
        order1.order_items << order_item
        order1.discard
        expect(Order.find_by(:id => order1.id)).to be_nil
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
      end
    end
  end

  describe "#undiscard before hook" do
    context "when the order has order items" do
      let!(:order_item) { create(:order_item, :order_id => order1.id) }

      before do
        order1.order_items << order_item
        order1.save
        order1.discard
      end

      it "restores the order items associated with the order" do
        expect(Order.find_by(:id => order1.id)).to be_nil
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
        order1 = Order.with_discarded.discarded.first
        order1.undiscard
        expect(Order.find_by(:id => order1.id)).to_not be_nil
        expect(OrderItem.find_by(:id => order_item.id)).to_not be_nil
      end
    end
  end

  context "updating order progress messages" do
    it "syncs the time between order and progress message" do
      order1.update_message("test_level", "test message")
      order1.reload
      last_message = order1.progress_messages.last
      expect(order1.updated_at).to be_a(Time)
      expect(last_message.message).to eq("test message")
      expect(last_message.messageable_type).to eq(order1.class.name)
      expect(last_message.messageable_id.to_i).to eq(order1.id)
      expect(last_message.tenant_id).to eq(order1.tenant.id)
    end
  end

  describe "#mark_completed" do
    it "marks the order as completed" do
      order1.mark_completed("Cool")
      expect(order1.state).to eq("Completed")
      expect(order1.completed_at).to be_truthy
      expect(order1.progress_messages.last.message).to match(/Cool/)
    end
  end

  describe "#mark_failed" do
    it "marks the order as failed" do
      order1.mark_failed("Too bad")
      expect(order1.state).to eq("Failed")
      expect(order1.completed_at).to be_truthy
      expect(order1.progress_messages.last.message).to match(/Too bad/)
    end
  end

  describe "#mark_canceled" do
    it "marks the order as failed" do
      order1.mark_canceled
      expect(order1.state).to eq("Canceled")
      expect(order1.completed_at).to be_truthy
      expect(order1.progress_messages).to be_empty
    end
  end

  describe "#mark_ordered" do
    it "marks the order as failed" do
      order1.mark_ordered
      expect(order1.state).to eq("Ordered")
      expect(order1.order_request_sent_at).to be_truthy
      expect(order1.progress_messages).to be_empty
    end
  end

  describe "#mark_approval_pending" do
    it "marks the order as failed" do
      order1.mark_approval_pending
      expect(order1.state).to eq("Approval Pending")
      expect(order1.progress_messages).to be_empty
    end
  end
end
