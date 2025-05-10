package com.hilgo.cargo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.hilgo.cargo.entity.Distributor;
import com.hilgo.cargo.entity.User;

public interface DistributorRepository extends JpaRepository<Distributor, Long>{

	Optional<User> findByUsername(String username);

}
