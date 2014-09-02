require 'spec_helper'

describe InstitutionPolicy do 
	
  let(:institution) { FactoryGirl.create(:institution) }
  let(:other_institution) { FactoryGirl.create(:institution) }
  let(:admin) { FactoryGirl.create(:user, :admin, institution_pid: institution.pid) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin, 
                                     institution_pid: institution.pid) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_user, 
                                     institution_pid: institution.pid) }
  let(:user) { FactoryGirl.create(:user) }

  context "for an admin user" do
    subject (:institution_policy) { InstitutionPolicy.new(admin, institution) }
  	
  	it { should permit(:create)      }
    it { should permit(:create_through_institution) }
    it { should permit(:new)         }
    it { should permit(:show)        }
    it { should permit(:update)      }
    it { should permit(:edit)        }
    it { should permit(:add_user)    }
    it { should_not permit(:destroy) }
  end

  context "for an institutional admin user" do
      	
  	describe "when the institution is" do
      describe "in my institution" do
        subject (:institution_policy) { InstitutionPolicy.new(inst_admin, institution) }
      	it { should permit(:show)        }
        it { should_not permit(:create)  }
        it { should permit(:create_through_institution) }
        it { should_not permit(:new)     }
        it { should permit(:update)      }
        it { should permit(:edit)        }
        it { should permit(:add_user)    }
        it { should_not permit(:destroy) }
      end

      describe "not in my institution" do
        subject (:institution_policy) { InstitutionPolicy.new(inst_admin, other_institution) }
        it { should_not permit(:create)  }
        it { should_not permit(:create_through_institution) }
        it { should_not permit(:new)     }
        it { should_not permit(:show)    }
        it { should_not permit(:update)      }
        it { should_not permit(:edit)        }
        it { should_not permit(:add_user)    }
        it { should_not permit(:destroy) }
      end
    end
  end

  context "for an institutional user" do
    describe "when the institution is" do
      describe "in my institution" do
    	 subject (:institution_policy) { InstitutionPolicy.new(inst_user, institution) }

        it { should permit(:show)        }
        it { should_not permit(:create)  }
        it { should_not permit(:create_through_institution) }
        it { should_not permit(:new)     }    
        it { should_not permit(:update)  }
        it { should_not permit(:edit)    }
        it { should_not permit(:add_user)    }
        it { should_not permit(:destroy) }
      end

      describe "not in my institution" do
        subject (:institution_policy) { InstitutionPolicy.new(inst_user, other_institution) }
    
        it { should_not permit(:create)  }
        it { should_not permit(:create_through_institution) }
        it { should_not permit(:new)     } 
        it { should_not permit(:show)    }
        it { should_not permit(:update)      }
        it { should_not permit(:edit)        }
        it { should_not permit(:add_user)    }
        it { should_not permit(:destroy) }
      end
    end
  end

	context "for an authenticated user without a user group" do
    subject (:institution_policy) { InstitutionPolicy.new(user, institution) }

    it { should_not permit(:show)    }
    it { should_not permit(:create)  }
    it { should_not permit(:create_through_institution) }
    it { should_not permit(:new)     }    
    it { should_not permit(:update)  }
    it { should_not permit(:edit)    }
    it { should_not permit(:add_user)    }
    it { should_not permit(:destroy) }
  end
end