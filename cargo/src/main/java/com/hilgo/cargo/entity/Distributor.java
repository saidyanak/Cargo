package com.hilgo.cargo.entity;

import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Distributor extends User{

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Column
	private String vkn;
	
	@OneToOne
	private Address address;
	
	@OneToMany(mappedBy = "driver")
	private List<Cargo> cargo;
}
