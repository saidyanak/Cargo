package com.hilgo.cargo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.hilgo.cargo.entity.Driver;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Long>{

	Driver findByCargoId(Long cargoId);

    Optional<Driver> findByTc(String tcOrVkn);
	
}
