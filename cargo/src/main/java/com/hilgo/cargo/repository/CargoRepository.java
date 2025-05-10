package com.hilgo.cargo.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.hilgo.cargo.entity.Cargo;

public interface CargoRepository extends JpaRepository<Cargo, Long>{
	Optional<Cargo> findByIdAndDistributorId(Long cargoId, Long distributorId);
	Optional<Cargo> findByIdAndDriverId(Long cargoId, Long driverId);
	List<Cargo> findAllByDistributorId(Long id);


}
