module ApplicationHelper
  def compute_total_enrollment(group)
    group.map(&:enrollment).inject(:+)
  end

  def compute_weighted_average_for_item(x, group)
    group.inject(0) { |sum, eval| sum += eval.enrollment * eval.send("item#{x}_mean".to_sym) } / compute_total_enrollment(group)
  end

  def compute_mean_student_eval_score(group)
    (1..8).inject(0) { |sum, x| sum += compute_weighted_average_for_item(x, group) } / 8
  end

  def compute_course_level_average(group, groups)
    groups = groups.reject { |g| g.first.course.to_s[0] != group.first.course.to_s[0] }.
        map { |g| compute_mean_student_eval_score(g) }
    groups.reduce(:+) / groups.size
  end

  def compute_mean_gpr(group)
    gprs = group.map(&:gpr)
    return nil if gprs.any?(&:nil?)
    gprs.inject(:+) / gprs.size
  end

  def compute_course_level_mean_gpr(group, groups)
    groups = groups.reject { |g| g.first.course.to_s[0] != group.first.course.to_s[0] }.
		map {|g| compute_mean_gpr(g) }.reject{ |g| g == nil}
	return nil if groups.size == 0
    groups.reduce(:+) / groups.size
  end
end
