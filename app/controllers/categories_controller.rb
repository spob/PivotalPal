class CategoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  before_filter :find_category, :only => [:show, :edit, :update, :destroy]
  respond_to :html, :xml

  # GET /categories
  # GET /categories.xml
  def index
    @categories = Category.where(:tenant_id => current_user.tenant).order("name").page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)

    respond_with @categories
  end

  # GET /categories/1
  # GET /categories/1.xml
  def show
    respond_with @category
  end

# GET /categories/new
# GET /categories/new.xml
  def new
    @category = Category.new

    respond_with @category
  end

# GET /categories/1/edit
  def edit
  end

# POST /categories
# POST /categories.xml
  def create
    @category = Category.new(params[:category])
    @category.tenant = current_user.tenant

    respond_to do |format|
      if @category.save
        format.html { redirect_to(categories_path, :notice => t('general.created', :entity => t('category.entity_name'))) }
        format.xml { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

# PUT /categories/1
# PUT /categories/1.xml
  def update
    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.html { redirect_to(@category,
                                  :notice => t('general.updated',
                                               :entity => t('category.entity_name'),
                                               :identifier => @category.name)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

# DELETE /categories/1
# DELETE /categories/1.xml
  def destroy
    name = @category.name
    @category.destroy

    respond_to do |format|
      format.html { redirect_to(categories_path,
                                :notice => t('general.deleted',
                                             :entity => t('category.entity_name'),
                                             :identifier => name)) }
      format.xml { head :ok }
    end
  end

  private

  def find_category
    @category = Category.find(params[:id])
  end
end
