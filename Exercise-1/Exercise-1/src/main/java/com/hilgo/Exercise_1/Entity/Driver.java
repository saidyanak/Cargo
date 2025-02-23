package com.hilgo.Exercise_1.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

@Entity
public class Driver extends User{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Column
	private Long Tc;
	
	@Column
	private String location;
	
	@Column
	private CarTypes carTypes;
	
	@ManyToOne()
	@JoinColumn(name = "cargo_id")
	private Cargo cargo;
}
