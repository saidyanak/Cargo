package com.hilgo.Exercise_1.repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.hilgo.Exercise_1.Entity.Distributor;

public interface DistributorRepository extends JpaRepository<Distributor, Long>{
	Optional<Distributor> findByUsername(String username);
}
