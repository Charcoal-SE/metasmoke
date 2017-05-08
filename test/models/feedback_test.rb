require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase
  test 'should cache feedback' do
    p = Post.new
    p.save!

    refute p.is_tp
    refute p.is_fp

    f = Feedback.new
    f.post = p
    f.feedback_type = 'tpu-'
    f.save!

    assert p.is_tp
    refute p.is_fp

    f = Feedback.new
    f.post = p
    f.feedback_type = 'fpu-'
    f.save!

    assert p.is_tp
    assert p.is_fp
  end

  test 'should invalidate feedback cache' do
    p = Post.new
    p.save!

    true_feedback = Feedback.new
    true_feedback.post = p
    true_feedback.feedback_type = 'tpu-'
    true_feedback.save!

    false_feedback = Feedback.new
    false_feedback.post = p
    false_feedback.feedback_type = 'fpu-'
    false_feedback.save!

    true_feedback.is_invalidated = true
    true_feedback.save!

    refute p.is_tp
    assert p.is_fp

    false_feedback.is_invalidated = true
    false_feedback.save!

    refute p.is_tp
    refute p.is_fp
  end
end
