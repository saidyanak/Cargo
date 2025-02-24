package com.hilgo.Exercise_1.Entity;

import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
public class Distributor extends User{

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Column
	private Long vkn;
	
	@Column
	private String address;

	@OneToMany(mappedBy = "distributor")
	private List<Cargo> cargo;
}
