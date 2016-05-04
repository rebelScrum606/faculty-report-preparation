class EvaluationController < ApplicationController

  before_action :authenticate_user!

  def new
    if can? :write, :all
      @evaluation = Evaluation.new
      # pluck call must remain :name, :id to have the correct ordering for the select box helper
      @instructors = Instructor.select_menu_options
      render layout: "layouts/centered_form"
    else
      redirect_to evaluation_index_path
    end
  end

  def create
    key_attrs, other_attrs = split_attributes(evaluation_params)

    @evaluation = Evaluation.where(key_attrs).first_or_initialize
    @evaluation.assign_attributes(other_attrs)
    @evaluation.save

    if @evaluation.errors.empty?
      flash[:notice] = "Evaluation created."
      redirect_to evaluation_index_path(term: @evaluation.term)
    else
      flash[:errors] = @evaluation.errors
      @instructors = Instructor.select_menu_options
      render 'new', layout: "layouts/centered_form"
    end
  end

  def index
    if can? :read, :all
      latest_term = params[:term] || Evaluation.no_missing_data.pluck(:term).uniq.sort.reverse.first
      if latest_term.nil?
        flash[:notice] = "No evaluation data exists yet! Try importing some."
        redirect_to root_path
      else
        redirect_to evaluation_path(id: latest_term)
      end
    else
      redirect_to root_path
    end
  end

  def show
    if can? :read, :all
      term = params[:id] || Evaluation.no_missing_data.pluck(:term).uniq.sort.reverse.first
      @evaluation_groups = Evaluation.no_missing_data.where(term: term).default_sorted_groups
      @terms = Evaluation.pluck(:term).uniq.sort.reverse
    else
      redirect_to root_path
    end
  end

  def missing_data
    if can? :read, :all
      @evaluation_groups = Evaluation.missing_data.default_sorted_groups
    else
      redirect_to root_path
    end
  end

  def import
    if can? :write, :all
      render layout: "layouts/centered_form"
    else
      redirect_to evaluation_index_path
    end
  end

  def import_gpr
    if can? :write, :all
      render layout: "layouts/centered_form"
    else
      redirect_to evaluation_index_path
    end
  end

  def export
    term = params.require(:id)
    evaluation_groups = Evaluation.no_missing_data.where(term: term).default_sorted_groups
    send_data EvaluationReportExporter.new(evaluation_groups).generate, filename: "#{term}_evaluation_report_#{Time.now.strftime('%F')}.csv"
  end

  def edit
    @evaluation = Evaluation.find(evaluation_id)
    @instructors = Instructor.select_menu_options
    render layout: "layouts/centered_form"
  end

  def destroy
    @evaluation = Evaluation.find(evaluation_id)
    key_string = @evaluation.key.values.map(&:to_s).join("-")
    @evaluation.destroy
    flash[:notice] = "The evaluation for #{key_string} has been deleted."
    redirect_to evaluation_index_path
  end

  def update
    @evaluation = Evaluation.find(evaluation_id)
    @evaluation, _ = Evaluation.create_if_needed_and_update(@evaluation.key, evaluation_params)
    if @evaluation.errors.empty?
      flash[:notice] = "Evaluation updated."
      redirect_to evaluation_path(id: @evaluation.term)
    else
      flash[:errors] = @evaluation.errors
      @instructors = Instructor.select_menu_options
      render 'edit'
    end
  end

  def upload
    if params[:data_file] != nil
      importer = ::PicaReportImporter.new(params.require(:data_file).tempfile)
      importer.import
      results = importer.results

      flash[:notice] = "#{results[:created]} new evaluations imported. #{results[:updated]} evaluations updated. #{results[:failed]} evaluations were not imported."
      redirect_to evaluation_index_path
    else
      flash[:errors] = "File not attached, please select file to upload"
      redirect_to import_evaluation_index_path
    end
  rescue ::PicaReportImporter::MalformedFileException => ex
    flash[:errors] = ex.to_s
    redirect_to import_evaluation_index_path
  rescue
    flash[:errors] = "There was an error parsing that XLSX file. Maybe it is corrupt? Please note that only XLSX files are supported, not XLS."
    redirect_to import_evaluation_index_path
  end

  def upload_gpr
    unless params[:term] && params[:term].match(/\A[12][0-9]{3}[A-Z]\z/)
      flash[:errors] = "Term is either missing or in the incorrect format."
      redirect_to import_gpr_evaluation_index_path
      return
    end

    if params[:data_file].nil?
      flash[:errors] = "File not attached, please select file to upload"
      redirect_to import_gpr_evaluation_index_path
      return
    end

    importer = ::GradeDistributionReportImporter.new(params.require(:data_file).tempfile, params[:term])
    importer.import
    results = importer.results

    flash[:notice] = "#{results[:created]} new GPRs imported. #{results[:updated]} evaluation GPRs updated. #{results[:failed]} evaluation GPRs were not imported."
    redirect_to evaluation_index_path
  rescue PDF::Reader::MalformedPDFError => ex
    flash[:errors] = "There was an error parsing that PDF file. Maybe it is corrupt?"
    redirect_to import_gpr_evaluation_index_path
  end

  private
  def split_attributes(all_attrs)
      # key attributes are ones for which we should have one unique record for a set of them
      key_attributes = all_attrs.select { |k,v| Evaluation.key_attributes.include?(k.to_sym) }

      # other atttributes are ones that should either be assigned or updated
      other_attributes = all_attrs.reject { |k,v| Evaluation.key_attributes.include?(k.to_sym) }
      if other_attributes[:instructor] && !other_attributes[:instructor].instance_of?(Instructor) && !other_attributes[:instructor].empty?
        other_attributes[:instructor] = Instructor.where(name: Instructor.normalize_name(other_attributes[:instructor])).first_or_create
      elsif other_attributes[:instructor_id] && other_attributes[:instructor_id] != "0"
        other_attributes[:instructor] = Instructor.where(id: other_attributes[:instructor_id]).first
        other_attributes.delete(:instructor_id)
      end

      [ key_attributes, other_attributes ]
  end

  def evaluation_params
    params.require(:evaluation).permit(:term, :subject, :course, :section, :instructor_id,
      :enrollment, :item1_mean, :item2_mean, :item3_mean, :item4_mean, :item5_mean,
      :item6_mean, :item7_mean, :item8_mean, :instructor, :gpr).to_h.symbolize_keys!
  end

  def evaluation_id
    params.require(:id)
  end
end
