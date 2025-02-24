package com.hilgo.Exercise_1.repo;

import org.springframework.data.domain.Page;
import org.springframework.data.jpa.repository.JpaRepository;

import com.hilgo.Exercise_1.Entity.Cargo;

public interface CargoRepository extends JpaRepository<Cargo, Long>{
	Page<Cargo> findByDistributorId(Long distributorId, org.springframework.data.domain.Pageable pageable);
	 
}
