class Instructor < ActiveRecord::Base
  has_many :evaluations

  validates :name, presence: true, uniqueness: true

  def course_section_groups
    evaluations.no_missing_data.default_sorted_groups
  end

  def self.select_menu_options
    # pluck call must remain :name, :id to have the correct ordering for the select box helper
    order(:name).pluck(:name, :id).push([ "New instructor...", 0 ])
  end

  def self.normalize_name(name)
    return nil unless name
    name.split.map(&:capitalize).join(" ")
  end
end
